#!/usr/bin/env bash
# メモリ枯渇防止: 多層防御セットアップスクリプト
# 使い方: sudo bash ~/.config/hypr/scripts/setup_memory_defense.sh
#
# 設計方針:
#   macOS / Windows がメモリ管理でやっていることは「圧縮」「足りない時に殺す」の 2 つ.
#   本スクリプトはその 2 つを Linux 上で再現する.
#     圧縮 -> zram    (macOS の Compressed Memory / Windows の Memory Compression 相当)
#     殺す -> earlyoom (macOS の jetsam 相当)
#   キャッシュを捨てる drop_caches の類は逆効果なので一切行わない.
#
# 実行内容:
#   1. zram-generator インストール・設定 (圧縮スワップ)
#   2. sysctl メモリチューニング (zram を実際に働かせる)
#   3. zswap 無効化 (zram との二重圧縮を防止)
#   4. earlyoom インストール・設定 (OOM 防止デーモン)
#
# 冪等性: 何度実行しても同じ結果になる. 既存の設定ファイルは .bak-<日時> に退避する.

set -uo pipefail

# root 権限チェック
if [[ $EUID -ne 0 ]]; then
    echo "エラー: このスクリプトは root 権限で実行してください"
    echo "  sudo bash $0"
    exit 1
fi

STAMP=$(date '+%Y%m%d-%H%M%S')

# 既存ファイルを退避してから上書きするためのヘルパ
backup_if_exists() {
    local f="$1"
    if [[ -f "$f" ]]; then
        cp -a "$f" "${f}.bak-${STAMP}"
        echo "  -> 既存の $f を ${f}.bak-${STAMP} に退避しました"
    fi
}

echo "=== メモリ枯渇防止: 多層防御セットアップ ==="
echo ""

# --------------------------------------------------------------------------
# Step 1: zram-generator (圧縮スワップ)
# --------------------------------------------------------------------------
echo "[1/4] zram-generator のインストール・設定..."

if ! pacman -Q zram-generator &>/dev/null; then
    pacman -S --noconfirm zram-generator
    echo "  -> zram-generator をインストールしました"
else
    echo "  -> zram-generator は既にインストール済み"
fi

backup_if_exists /etc/systemd/zram-generator.conf
cat > /etc/systemd/zram-generator.conf << 'ZRAMEOF'
[zram0]
# 物理 RAM の半分を zram に割り当てる.
# zstd の圧縮率はおおむね 3 倍前後なので, 実効的にはこの 3 倍程度の余裕が生まれる.
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
ZRAMEOF
echo "  -> /etc/systemd/zram-generator.conf を作成しました"

systemctl daemon-reload

if swapon --show 2>/dev/null | grep -q zram; then
    echo "  -> zram スワップは既に有効"
else
    systemctl start systemd-zram-setup@zram0.service 2>/dev/null || true
    if swapon --show 2>/dev/null | grep -q zram; then
        echo "  -> zram0 スワップを有効化しました"
    else
        echo "  ⚠ zram の自動有効化に失敗しました. 再起動後に swapon --show で確認してください"
    fi
fi

echo ""

# --------------------------------------------------------------------------
# Step 2: sysctl チューニング
# --------------------------------------------------------------------------
echo "[2/4] sysctl メモリ最適化パラメータの設定..."

SYSCTL_CONF=/etc/sysctl.d/90-memory-optimization.conf
backup_if_exists "$SYSCTL_CONF"

cat > "$SYSCTL_CONF" << 'SYSCTLEOF'
# メモリ枯渇防止: sysctl チューニング (zram を主スワップとする構成向け)
# カーネル既定値からの変更点: swappiness 60->180, watermark_scale_factor 10->125,
#                             page-cluster 3->0, vfs_cache_pressure 100->150

# zram は RAM 上の圧縮領域でディスクより桁違いに速いため, 積極的に退避させる.
# 既定の 60 のままだと zram がほとんど使われず, 確保した圧縮領域が遊んでしまう.
vm.swappiness = 180

# zram はシークが不要なので, スワップイン時の先読み (2^3 = 8 ページ) は無駄になる
vm.page-cluster = 0

# kswapd による回収開始を早め, 空きが尽きてからの急激な失速を防ぐ
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125

# dentry/inode キャッシュの回収を積極化
vm.vfs_cache_pressure = 150

# 200MB の空きメモリを常時確保
vm.min_free_kbytes = 204800

# ダーティページを早めにフラッシュし, 書き戻しの詰まりを防ぐ
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
SYSCTLEOF
echo "  -> $SYSCTL_CONF を作成しました"

sysctl --system > /dev/null 2>&1
echo "  -> sysctl パラメータを即時適用しました"

echo ""

# --------------------------------------------------------------------------
# Step 3: zswap 無効化 (zram との二重圧縮を防止)
# --------------------------------------------------------------------------
echo "[3/4] zswap の無効化 (zram との二重圧縮を防止)..."

# zswap はディスクスワップの手前に置く圧縮キャッシュなので, スワップが zram だけの
# 構成では「圧縮領域の手前で圧縮する」二重処理になり, CPU と管理コストが無駄になる.

if [[ -w /sys/module/zswap/parameters/enabled ]]; then
    if echo N > /sys/module/zswap/parameters/enabled 2>/dev/null; then
        echo "  -> zswap を即時無効化しました"
    else
        echo "  ⚠ zswap の即時無効化に失敗しました"
    fi
else
    echo "  -> zswap のパラメータが見つかりません (無効化不要)"
fi

# 永続化: ブートローダーの設定を書き換えるのは失敗時のリスクが大きいため,
# systemd-tmpfiles で起動のたびに sysfs へ書き込む方式を採る.
# こちらはブートローダーの種類 (systemd-boot / GRUB / UKI) に依存しない.
TMPFILES_CONF=/etc/tmpfiles.d/zswap-off.conf
backup_if_exists "$TMPFILES_CONF"
cat > "$TMPFILES_CONF" << 'TMPEOF'
# 起動のたびに zswap を無効化する (zram との二重圧縮を防ぐ)
# 書式: 型 パス モード UID GID 保持期間 引数
w /sys/module/zswap/parameters/enabled - - - - N
TMPEOF
systemd-tmpfiles --create "$TMPFILES_CONF" > /dev/null 2>&1 || true
echo "  -> $TMPFILES_CONF を作成しました (再起動後も無効のまま維持されます)"

echo ""

# --------------------------------------------------------------------------
# Step 4: earlyoom (OOM 防止デーモン)
# --------------------------------------------------------------------------
echo "[4/4] earlyoom のインストール・設定..."

if ! pacman -Q earlyoom &>/dev/null; then
    pacman -S --noconfirm earlyoom
    echo "  -> earlyoom をインストールしました"
else
    echo "  -> earlyoom は既にインストール済み"
fi

mkdir -p /etc/default
backup_if_exists /etc/default/earlyoom

cat > /etc/default/earlyoom << 'EARLYOOMEOF'
# earlyoom 設定
#
# -m 8,4  : 空きメモリ 8% で SIGTERM, 4% で SIGKILL
#           (RAM 13.5GB 換算で およそ 1.1GB / 550MB)
# -s 10,5 : zram の空きが 10% で SIGTERM, 5% で SIGKILL
# -r 3600 : 状態のログ出力は 1 時間に 1 回だけ (journal を埋めないため)
# -n      : デスクトップ通知を送信
#
# --avoid : 絶対に終了させないプロセス.
#           herdr と fish を含めるのが重要で, これらを殺されると全ペインが道連れになる.
#           プロセス名は大文字小文字を区別するため Hyprland は H が大文字であることに注意.
# --prefer: 優先的に終了させるプロセス. ブラウザと Electron アプリを先に犠牲にすることで,
#           並列起動している claude が実質的に守られる設計にしている.
#           (claude を --avoid に入れると最後の逃げ道が無くなるため, あえて中立に置く)
EARLYOOM_ARGS="-m 8,4 -s 10,5 -r 3600 -n --avoid '(^Hyprland$|^hyprlock$|^hypridle$|^hyprpaper$|^waybar$|^herdr$|^fish$|^systemd|^dbus-daemon$|^pipewire|^wireplumber$|^sddm|^Xwayland$|^sshd$)' --prefer '(firefox|Isolated|Web Content|WebExtensions|slack|chrome|chromium|electron|Discord|obsidian|thunderbird)'"
EARLYOOMEOF
echo "  -> /etc/default/earlyoom を作成しました"

# EnvironmentFile を読まないパッケージ構成に備えて確認する
if ! systemctl cat earlyoom.service 2>/dev/null | grep -qi 'EnvironmentFile=.*earlyoom'; then
    echo "  ⚠ earlyoom.service が /etc/default/earlyoom を読まない構成です. drop-in を作成します"
    mkdir -p /etc/systemd/system/earlyoom.service.d
    # shellcheck disable=SC1091
    source /etc/default/earlyoom
    cat > /etc/systemd/system/earlyoom.service.d/override.conf << OVERRIDEEOF
[Service]
ExecStart=
ExecStart=/usr/bin/earlyoom ${EARLYOOM_ARGS}
OVERRIDEEOF
fi

systemctl daemon-reload
systemctl enable --now earlyoom
echo "  -> earlyoom を有効化・起動しました"

echo ""

# --------------------------------------------------------------------------
# 検証
# --------------------------------------------------------------------------
echo "=== 検証 ==="
echo ""
echo "[zram]"
swapon --show
zramctl 2>/dev/null || true
echo ""
echo "[sysctl]"
sysctl vm.swappiness vm.page-cluster vm.watermark_scale_factor vm.vfs_cache_pressure vm.min_free_kbytes
echo ""
echo "[zswap]"
echo "  enabled = $(cat /sys/module/zswap/parameters/enabled 2>/dev/null || echo '不明')  (N が正常)"
echo ""
echo "[earlyoom]"
systemctl is-enabled earlyoom
systemctl is-active earlyoom
systemctl show earlyoom -p ExecStart --value | head -c 200; echo
echo ""
echo "[メモリ]"
free -h
echo ""
echo "=== セットアップ完了 ==="
echo ""
echo "ロールバック手順:"
echo "  sudo systemctl disable --now earlyoom"
echo "  sudo rm -f $SYSCTL_CONF $TMPFILES_CONF /etc/default/earlyoom"
echo "  sudo rm -rf /etc/systemd/system/earlyoom.service.d"
echo "  sudo sysctl --system"
