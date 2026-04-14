function trash
    # ディレクトリ ~/.trash を作成
    set trash_dir ~/.trash
    if not test -d $trash_dir
        mkdir -p $trash_dir
    end

    # 引数がない場合は使い方を表示
    if test (count $argv) -eq 0
        echo "Usage: trash <file_or_directory>"
        return 1
    end

    # ファイルを ~/.trash に移動
    for item in $argv
        if test -e $item
            set timestamp (date +%Y-%m-%d_%H-%M-%S)
            set filename (basename $item)
            set target "$trash_dir/$filename.$timestamp"
            mv $item $target
        else
            echo "Error: $item does not exist"
        end
    end
end
