# Path to Oh My Fish install.
set -q XDG_DATA_HOME
  and set -gx OMF_PATH "$XDG_DATA_HOME/omf"
  or set -gx OMF_PATH "$HOME/.local/share/omf"

# Load Oh My Fish configuration.
# Oh My Fish 未インストールの環境ではスキップ(プラグイン管理は Fisher)
test -f $OMF_PATH/init.fish; and source $OMF_PATH/init.fish
