function firefox --wraps firefox --description "相対パスを絶対パスに変換して firefox に渡す"
    # macOS では起動中の Firefox に相対パスを渡すと、Firefox 側の cwd で解決されて開けない
    # (例: nvim の `:!firefox %`)。実在するファイル引数は絶対パスに変換してから渡す
    set -l args
    for a in $argv
        if not string match -q -- '-*' $a; and test -e $a
            set -a args (path resolve -- $a)
        else
            set -a args $a
        end
    end
    command firefox $args
end
