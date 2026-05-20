-- ~/.config/nvim/lua/plugins/dashboard-header.lua
return {
  {
    "nvimdev/dashboard-nvim",
    opts = function(_, opts)
      -- replace only the header with your custom ANSI art
      opts.config.header = {
	"                                                  ",
	"                                                  ",
	"                                                  ",
	"                                                  ",
        "███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
        "████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
        "██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
        "██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
        "██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
        "╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝        ╚═╝",
        "",
        "                The Matrix has us...",
      }
    end,
  },
}

