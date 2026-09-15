-- Client-side extensions for eclipse.jdt.ls (extra commands, better UI for code
-- actions). The server binary is installed by mason ('jdtls' in init.lua's
-- ensure_installed). Startup happens per Java buffer in ftplugin/java.lua —
-- nvim-jdtls's start_or_attach model — rather than through the lspconfig servers
-- table.
local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'mfussenegger/nvim-jdtls' }
