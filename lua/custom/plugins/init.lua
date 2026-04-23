-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  {
    'rmagatti/auto-session',
    lazy = true,
    --@module "auto-session"
    --@type AutoSession.Config
    opts = {
      allowed_dirs = {},
      suppressed_dirs = {},
    },
  },
}
