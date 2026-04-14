return {
  'nvimdev/dashboard-nvim',
  cmd = 'Dashboard',
  opts = {
    theme = 'hyper',
    config = {
      header = {
        "      ∩∩                                           ", 
        "   （´･ω･）                                        ", 
        "   ＿| ⊃／(＿＿_     ┏┓                     ┏┓     ", 
        " ／ └-(＿＿＿_／   ┏━┛┗━┓          ┏┓      ┏┛┗━┓   ", 
        " ￣￣￣￣￣￣￣    ┗━┓┏━┏┓ ┏━━━━┓ ┏┛┗━━┏┓  ┗┓┏┓┃   ", 
        "                   ┏━┛┗━┗┛ ┏━━━┛┃ ┗┓┏━┓┃┃  ┏┛┃┃┃   ", 
        "   ⊂⌒／ヽ-、＿_    ┃□ ┏┓┃  ┗━━━━┛  ┃┃ ┃┗┛  ┗┓┃┃┗┓  ", 
        " ／⊂_/＿＿＿＿ ／  ┗━━┛┗┛          ┗┛ ┗┛    ┗┛┗━┛  ", 
      },
      center = {
        { icon = '  ', desc = 'New File', action = 'DashboardNewFile' },
        { icon = '  ', desc = 'Open File Explorer', action = 'Neotree toggle' },
        { icon = '  ', desc = 'Recent Files', action = 'Telescope oldfiles' },
      },
      footer = {'Have a great day!'},
    }
  },
  dependencies = { {'nvim-tree/nvim-web-devicons'}}
}
