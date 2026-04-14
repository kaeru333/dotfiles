set -Ux EDITOR nvim
set -Ux VISUAL nvim
set -x INFORMIXDIR ~/Downloads
set -gx VIRTUAL_ENV_DISABLE_PROMPT 1

# Bluetooth デバイス
set -gx EARBUDS_MAC "E8:EE:CC:AC:ED:08"

# OS判定
set -g IS_MACOS (test (uname) = "Darwin"; and echo 1; or echo 0)
set -g IS_LINUX (test (uname) = "Linux"; and echo 1; or echo 0)

# Homebrew / Linuxbrew
if test "$IS_MACOS" = 1
    fish_add_path /opt/homebrew/bin
else
    fish_add_path /home/linuxbrew/.linuxbrew/bin
end

# 共通PATH
fish_add_path $HOME/go/bin
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.npm-global/bin
fish_add_path $HOME/.cabal/bin
fish_add_path $HOME/.ghcup/bin

source $HOME/.config/fish/abbr/abbr.fish
source $HOME/.config/fish/myconf.d/bobthefish.fish

# Linux専用設定
if test "$IS_LINUX" = 1
    fish_add_path /opt/f5/vpn
    fish_add_path $HOME/anaconda3/bin

    # IME (fcitx)
    set -x GTK_IM_MODULE fcitx
    set -x QT_IM_MODULE fcitx
    set -x XMODIFIERS "@im=fcitx"
end

function fuck -d "Correct your previous console command"
    set -l fucked_up_command $history[1]
    set -l unfucked_command (env TF_SHELL=fish TF_ALIAS=fuck PYTHONIOENCODING=utf-8 thefuck $fucked_up_command THEFUCK_ARGUMENT_PLACEHOLDER $argv)
    if test "$unfucked_command" != ""
        eval $unfucked_command
        builtin history delete --exact --case-sensitive -- $fucked_up_command
        builtin history merge
    end
end

if status is-interactive
    # 既存のセッションがなければ、新規作成
    if tmux ls &> /dev/null
        # 既存のセッションにアタッチ
        tmux attach-session
    else
        # 新規セッションを作成し、tmux-resurrectでセッションを自動復元
        set -l resurrect_script $HOME/.config/tmux/plugins/tmux-resurrect/scripts/restore.sh
        if test -f $resurrect_script
            tmux new-session \; run-shell $resurrect_script
        else
            tmux new-session
        end
    end
end

function ya
    set tmp (mktemp -t "yazi-cwd.XXXXX")
    yazi --cwd-file="$tmp"
    if test -f "$tmp"
        set cwd (cat -- "$tmp")
        if test -n "$cwd" -a "$cwd" != "$PWD"
            cd -- "$cwd"
        end
    end
    rm -f -- "$tmp"
end

set -U FISH_CACHE_DIR "$HOME/.cache/fish"
set -l CONFIG_CACHE "$FISH_CACHE_DIR"/config.fish

if test "$FISH_CONFIG" -nt "$CONFIG_CACHE"
    mkdir -p $FISH_CACHE_DIR
    echo '' >$CONFIG_CACHE

    # conda のキャッシュ追加
    if type -q conda
        set conda_root (conda info --root)
        echo "source $conda_root/etc/fish/conf.d/conda.fish" >>$CONFIG_CACHE
    end

    echo "config cache updated"
end
source $CONFIG_CACHE

set -q GHCUP_INSTALL_BASE_PREFIX[1]; or set GHCUP_INSTALL_BASE_PREFIX $HOME

functions -q fish_postexec
