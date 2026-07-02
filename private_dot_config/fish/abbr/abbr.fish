abbr -a vi nvim
abbr -a :q exit
abbr -a ls eza --icons --color
abbr -a lsd eza --icons --color -D
abbr -a la eza --color -all
abbr -a df duf
abbr -a tree eza -T
abbr -a treed eza -T -D
abbr -a cat bat
abbr -a top gotop
abbr -a python python3
abbr -a py python3
abbr -a pyt ~/.local/bin/oj t -c '"python3 main.py"' -d ./tests/
abbr -a trn tr -d "\n"

# claude code
abbr -a cc "claude --dangerously-skip-permissions"
abbr -a ccr "claude --dangerously-skip-permissions -r"
abbr -a ca "claude -p"

abbr -a mcal "gcalcli --calendar='日程管理'"
abbr -a mm nbs

abbr -a "..." --position anywhere "../.."
abbr -a "...." --position anywhere "../../.."
abbr -a "....." --position anywhere "../../../.."
abbr -a "......" --position anywhere "../../../../.."
abbr -a G --position anywhere "| grep"
abbr -a F --position anywhere "| fzf"
abbr -a Trn --position anywhere "| tr -d '\n'"
abbr -a R --position anywhere "| lolcat"
abbr -a St --position anywhere "--sort=time"

# translate-shell
abbr -a te "trans -b :en"
abbr -a tj "trans -b :ja"
abbr -a Te --position anywhere "| trans -b :en"
abbr -a Tj --position anywhere "| trans -b :ja"

# unzip: Windows (CP932) 由来の zip でも文字化けしないように
abbr -a unzip "unzip -O cp932"

# -----------------------------------------------------------------------------
# 秘匿値はリポジトリにコミットしない。各マシンで universal 変数として設定する
# （~/.config/fish/fish_variables に保存され、.chezmoiignore で git 管理外）:
#   set -U AWS_SSO_ACCOUNT <AWS アカウントID>
#   set -U TSUBAME_HOST    <user@host>
# 未設定でもエラーにはならず、展開結果が空になるだけ。
# -----------------------------------------------------------------------------
abbr -a awsec2 "aws sso login --profile AWSAdministratorAccess-$AWS_SSO_ACCOUNT"
abbr -a --position anywhere -- TSUBAME "scp://$TSUBAME_HOST/gs/bs/tga-nakatalab/home"
abbr -a --position anywhere -- DAC25 "scp://tsubame//gs/bs/tga-nakatalab/home/dac25_nakata"

# OS別abbr
if test (uname) = "Darwin"
    abbr -a shut 'sudo shutdown -h now'
    abbr -a op open
    abbr -a pc pbcopy
    abbr -a pp pbpaste
    abbr -a pwdy 'pwd | tr -d "\n" | pbcopy'
    abbr -a C --position anywhere "| pbcopy"
else
    abbr -a shut shutdown now
    abbr -a op xdg-open
    abbr -a pc wl-copy
    abbr -a pp wl-paste
    abbr -a pwdy 'pwd | tr -d "\n" | wl-copy'
    abbr -a vol pactl set-sink-volume @DEFAULT_SINK@
    abbr -a C --position anywhere "| wl-copy"

    # Linux 専用ツールに依存する abbr（macOS では未定義）
    abbr -a screenshot 'grim -g "$(slurp)" ~/Pictures/screenshot/$(date +%s).png'  # grim/slurp (Wayland)
    abbr -a D --position anywhere "&& dunstify"                                      # dunst 通知
    abbr -a bc "bluetoothctl connect"                                               # BlueZ（macOS の bc(電卓)と衝突するため Linux 限定）
    abbr -a ob "nvim /home/yoshimi/myfiles/ScienceTokyo/nakatalab/study/log/home.md"
    abbr -a ja "node /home/yoshimi/myfiles/something/gemini_cli/gemini.js "
end
