function fish_user_key_bindings
    # Ctrl-X Ctrl-E: 現在のコマンドラインを $EDITOR (nvim) で開いて編集する
    # fish のデフォルトでは edit_command_buffer は Alt-E / Alt-V に割り当てられているが、
    # macOS の Terminal/iTerm では Option(Alt) がメタキーとして送られず効かないため、
    # bash 互換の C-x C-e を割り当てる（Linux/macOS 共通で動作する）。
    bind ctrl-x,ctrl-e edit_command_buffer
end
