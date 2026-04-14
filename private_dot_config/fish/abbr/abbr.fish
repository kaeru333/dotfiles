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
abbr -a screenshot 'grim -g "$(slurp)" ~/Pictures/screenshot/$(date +%s).png'

# claude code
abbr -a cc "claude --dangerously-skip-permissions"
abbr -a ccr "claude --dangerously-skip-permissions -r"
abbr -a ca "claude -p"

abbr -a mcal "gcalcli --calendar='日程管理'"
abbr -a mm nbs
abbr -a ob "nvim /home/yoshimi/myfiles/ScienceTokyo/nakatalab/study/log/home.md"
abbr -a ja "node /home/yoshimi/myfiles/something/gemini_cli/gemini.js "

abbr -a "..." --position anywhere "../.."
abbr -a "...." --position anywhere "../../.."
abbr -a "....." --position anywhere "../../../.."
abbr -a "......" --position anywhere "../../../../.."
abbr -a G --position anywhere "| grep"
abbr -a F --position anywhere "| fzf"
abbr -a Trn --position anywhere "| tr -d '\n'"
abbr -a R --position anywhere "| lolcat"
abbr -a D --position anywhere "&& dunstify"
abbr -a St --position anywhere "--sort=time"

# translate-shell
abbr -a te "trans -b :en"
abbr -a tj "trans -b :ja"
abbr -a Te --position anywhere "| trans -b :en"
abbr -a Tj --position anywhere "| trans -b :ja"

# Bluetooth デバイス
abbr -a bc "bluetoothctl connect"

# TSUBAME
abbr -a --position anywhere -- TSUBAME "scp://us04759@r4n11.titech.ac.jp/gs/bs/tga-nakatalab/home"
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
end
