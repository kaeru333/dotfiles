# rustup 未初期化のマシンではファイルが無いため，存在する場合のみ読み込む
test -r "$HOME/.cargo/env.fish"; and source "$HOME/.cargo/env.fish"
