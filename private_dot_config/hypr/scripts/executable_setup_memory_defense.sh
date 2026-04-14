#!/usr/bin/env bash
# メモリ枯渇防止: 多層防御セットアップスクリプト
# 使い方: sudo bash ~/.config/hypr/scripts/setup_memory_defense.sh
#
# 実行内容:
#   1. zram-generator インストール・設定 (圧縮スワップ)
#   2. sysctl メモリチューニング
#   3. zswap 無効化 (zram との二重圧縮を防止)
#   4. earlyoom インストール・設定 (OOM 防止デーモン)

set -euo pipefail

# root 権限チェック
if [[ $EUID -ne 0 ]]; then
    echo "エラー: このスクリプトは root 権限で実行してください"
    echo "  sudo bash $0"
    exit 1
fi

echo "=== メモリ枯渇防止: 多層防御セットアップ ==="
echo ""

# --------------------------------------------------------------------------
# Step 1: zram-generator
# --------------------------------------------------------------------------
echo "[1/4] zram-generator のインストール・設定..."

if ! pacman -Q zram-generator &>/dev/null; then
    pacman -S --noconfirm zram-generator
    echo "  -> zram-generator をインストールしました"
else
    echo "  -> zram-generator は既にインストール済み"
fi

cat > /etc/systemd/zram-generator.conf << 'ZRAMEOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
ZRAMEOF
echo "  -> /etc/systemd/zram-generator.conf を作成しました"

# zram デバイスを即座に作成 (再起動不要)
systemctl daemon-reload
if ! swapon --show | grep -q zram; then
    # systemd-zram-setup@zram0.service を起動
    systemctl start systemd-zram-setup@zram0.service 2>/dev/null || true
    # サービスが作成できない場合は手動でセットアップ
    if ! swapon --show | grep -q zram; then
        modprobe zram
        echo zstd > /sys/block/zram0/comp_algorithm 2>/dev/null || true
        local_ram_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        local_zram_bytes=$(( local_ram_kb * 1024 / 2 ))
        echo "$local_zram_bytes" > /sys/block/zram0/disksize
        mkswap /dev/zram0
        swapon -p 100 /dev/zram0
    fi
    echo "  -> zram0 スワップを有効化しました"
else
    echo "  -> zram スワップは既に有効"
fi

echo ""

# --------------------------------------------------------------------------
# Step 2: sysctl チューニング
# --------------------------------------------------------------------------
echo "[2/4] sysctl メモリ最適化パラメータの設定..."

cat > /etc/sysctl.d/90-memory-optimization.conf << 'SYSCTLEOF'
# メモリ枯渇防止: sysctl チューニング
# zram 環境向けの最適化

# zram 環境では高い swappiness が推奨 (RAM 内圧縮なのでペナルティなし)
vm.swappiness = 150

# dentry/inode キャッシュの回収を積極化
vm.vfs_cache_pressure = 150

# 200MB の空きメモリを常時確保
vm.min_free_kbytes = 204800

# kswapd を早めに起動 (デフォルト 10 → 30)
vm.watermark_scale_factor = 30

# ダーティページを早めにフラッシュ
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
SYSCTLEOF
echo "  -> /etc/sysctl.d/90-memory-optimization.conf を作成しました"

# 即時適用
sysctl --system > /dev/null 2>&1
echo "  -> sysctl パラメータを即時適用しました"

echo ""

# --------------------------------------------------------------------------
# Step 3: zswap 無効化
# --------------------------------------------------------------------------
echo "[3/4] zswap の無効化 (zram との二重圧縮を防止)..."

# 即時無効化
echo N > /sys/module/zswap/parameters/enabled
echo "  -> zswap を即時無効化しました"

# systemd-boot のカーネルパラメータに追加して永続化
# /efi/loader/entries/ 内の .conf ファイルを検索
boot_entries_dir="/efi/loader/entries"
if [[ -d "$boot_entries_dir" ]]; then
    modified=0
    for entry in "$boot_entries_dir"/*.conf; do
        [[ -f "$entry" ]] || continue
        if grep -q "^options" "$entry" && ! grep -q "zswap.enabled=0" "$entry"; then
            sed -i 's/^options \(.*\)/options \1 zswap.enabled=0/' "$entry"
            echo "  -> $entry に zswap.enabled=0 を追加しました"
            modified=1
        fi
    done
    if [[ $modified -eq 0 ]]; then
        echo "  -> ブートエントリは既に設定済み、または見つかりません"
        echo "  ⚠ 手動で確認してください: $boot_entries_dir/*.conf の options 行に zswap.enabled=0 を追加"
    fi
else
    echo "  ⚠ $boot_entries_dir が見つかりません"
    echo "  手動でブートローダーのカーネルパラメータに zswap.enabled=0 を追加してください"
fi

echo ""

# --------------------------------------------------------------------------
# Step 4: earlyoom
# --------------------------------------------------------------------------
echo "[4/4] earlyoom のインストール・設定..."

if ! pacman -Q earlyoom &>/dev/null; then
    pacman -S --noconfirm earlyoom
    echo "  -> earlyoom をインストールしました"
else
    echo "  -> earlyoom は既にインストール済み"
fi

mkdir -p /etc/default
cat > /etc/default/earlyoom << 'EARLYOOMEOF'
# earlyoom 設定
# -m 5,3: 空きメモリ 5% で SIGTERM、3% で SIGKILL
# -s 10,5: スワップ空き 10% で SIGTERM、5% で SIGKILL
# -r 5: 5 秒間隔でチェック
# -n: デスクトップ通知を送信
# --prefer: メモリ消費が大きいブラウザ/Electron を優先終了
# --avoid: デスクトップ基盤プロセスを保護
EARLYOOM_ARGS="-m 5,3 -s 10,5 -r 5 -n --prefer '(firefox|chromium|electron)' --avoid '(hyprland|waybar|dunst|pipewire|wireplumber)'"
EARLYOOMEOF
echo "  -> /etc/default/earlyoom を作成しました"

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
echo ""
echo "[sysctl]"
sysctl vm.swappiness vm.vfs_cache_pressure vm.min_free_kbytes
echo ""
echo "[zswap]"
echo "  enabled = $(cat /sys/module/zswap/parameters/enabled)"
echo ""
echo "[earlyoom]"
systemctl is-active earlyoom
echo ""
echo "=== セットアップ完了 ==="
echo "⚠ zswap の永続的な無効化にはブートローダー設定の確認が必要です"
echo "  次回の再起動後に cat /sys/module/zswap/parameters/enabled で N を確認してください"
