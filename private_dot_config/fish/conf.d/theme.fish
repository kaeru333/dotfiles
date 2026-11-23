# 配色モード (light / dark) の追従設定．
#
# 状態は universal 変数 $theme_mode に持つ．theme-toggle が
#   fish -c 'set -U theme_mode light'
# を実行すると，起動中のすべての fish セッションでハンドラが発火して即座に反映される．
# 実際の色は ~/.config/fish/themes/yoshimi.theme の [light] / [dark] から選ばれる．

if status is-interactive
    # 初回起動時のみ既定値を入れる (既定はライトモード) ．
    if not set -q theme_mode
        set -U theme_mode light
    end

    function __theme_apply --description '$theme_mode を現在のセッションに適用する'
        set -l mode dark
        test "$theme_mode" = light; and set mode light

        # bobthefish (プロンプト) の配色．
        if test "$mode" = light
            set -g theme_color_scheme catppuccin-latte
        else
            set -g theme_color_scheme dark
        end

        # fish 本体の構文ハイライト．
        # $fish_terminal_color_theme は読み取り専用 (端末が報告する) ため，
        # herdr 越しで検知できない場合に備えて --color-theme で明示する．
        fish_config theme choose yoshimi --color-theme=$mode
    end

    function __theme_mode_changed --on-variable theme_mode --description 'theme_mode の変更を反映する'
        __theme_apply
        commandline -f repaint
    end

    __theme_apply
end
