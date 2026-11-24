function chrome --description "相対パスを絶対パスに変換して Google Chrome に渡す"
    set -l args
    for a in $argv
        if not string match -q -- '-*' $a; and test -e $a
            set -a args (path resolve -- $a)
        else
            set -a args $a
        end
    end
    if test (uname) = Darwin
        open -a "Google Chrome" $args
    else
        command google-chrome-stable $args
    end
end
