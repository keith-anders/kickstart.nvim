-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

vim.pack.add {
  'https://github.com/mfussenegger/nvim-dap',
  'https://github.com/rcarriga/nvim-dap-ui',
  'https://github.com/nvim-neotest/nvim-nio',
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/jay-babu/mason-nvim-dap.nvim',
  'https://github.com/leoluz/nvim-dap-go',
}

-- Basic debugging keymaps, feel free to change to your liking!
-- Many terminals send Shift+F<n> as F<n+12>, so each shifted key is mapped under both names.
vim.keymap.set('n', '<F5>', function() require('dap').continue() end, { desc = 'Debug: Start/Continue' })
vim.keymap.set('n', '<S-F5>', function() require('dap').terminate() end, { desc = 'Debug: Terminate' })
vim.keymap.set('n', '<F17>', function() require('dap').terminate() end, { desc = 'Debug: Terminate' })
vim.keymap.set('n', '<F10>', function() require('dap').step_over() end, { desc = 'Debug: Step Over' })
vim.keymap.set('n', '<F12>', function() require('dap').step_into() end, { desc = 'Debug: Step Into' })
vim.keymap.set('n', '<S-F12>', function() require('dap').step_out() end, { desc = 'Debug: Step Out' })
vim.keymap.set('n', '<F24>', function() require('dap').step_out() end, { desc = 'Debug: Step Out' })
vim.keymap.set('n', '<leader>b', function() require('dap').toggle_breakpoint() end, { desc = 'Debug: Toggle Breakpoint' })
vim.keymap.set('n', '<leader>B', function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, { desc = 'Debug: Set Breakpoint' })
vim.keymap.set('n', '<F7>', function() require('dapui').toggle() end, { desc = 'Debug: Toggle UI' })

local dap = require 'dap'
local dapui = require 'dapui'

require('mason-nvim-dap').setup {
  -- Makes a best effort to setup the various debuggers with
  -- reasonable debug configurations
  automatic_installation = true,

  -- You can provide additional configuration to the handlers,
  -- see mason-nvim-dap README for more information
  handlers = {},

  -- You'll need to check that you have the required things installed
  -- online, please don't ask me how to install them :)
  ensure_installed = {
    -- Update this to ensure that you have the debuggers for the langs you want
    'delve',
  },
}

-- Dap UI setup
-- For more information, see |:help nvim-dap-ui|
---@diagnostic disable-next-line: missing-fields
dapui.setup {
  -- Set icons to characters that are more likely to work in every terminal.
  --    Feel free to remove or use ones that you like more! :)
  --    Don't feel like these are good choices.
  icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
  ---@diagnostic disable-next-line: missing-fields
  controls = {
    icons = {
      pause = '⏸',
      play = '▶',
      step_into = '⏎',
      step_over = '⏭',
      step_out = '⏮',
      step_back = 'b',
      run_last = '▶▶',
      terminate = '⏹',
      disconnect = '⏏',
    },
  },
}

-- Change breakpoint icons
-- vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
-- vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
-- local breakpoint_icons = vim.g.have_nerd_font
--     and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
--   or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
-- for type, icon in pairs(breakpoint_icons) do
--   local tp = 'Dap' .. type
--   local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
--   vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
-- end

-- nvim-dap's default stopped-line sign uses SignColumn and debugPC, which barely differ from Normal in most themes
vim.fn.sign_define('DapStopped', { text = '▶', texthl = 'DiagnosticWarn', linehl = 'DapStoppedLine', numhl = 'DiagnosticWarn' })

-- dap-ui stays open after the session ends so the program output and exit status remain readable; <F7> closes it.
dap.listeners.after.event_initialized['dapui_config'] = dapui.open

-- nvim-dap discards the exit code from the `exited` event, so surface it here.
dap.listeners.after.event_exited['kickstart_exit_code'] = function(session, body)
  local code = body and body.exitCode
  if code == nil then return end
  local name = session.config and session.config.name or 'Debuggee'
  vim.notify(string.format('%s exited with code %d', name, code), code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
end

-- On Windows, Mason exposes delve as `dlv.cmd`, which vim.uv.spawn cannot launch; use the underlying exe instead.
local delve_path = 'dlv'
if vim.fn.has 'win32' == 1 then
  local mason_dlv = vim.fn.stdpath 'data' .. '/mason/packages/delve/dlv.exe'
  if vim.fn.executable(mason_dlv) == 1 then delve_path = mason_dlv end
end

-- Install golang specific config
require('dap-go').setup {
  delve = {
    path = delve_path,
    -- On Windows delve must be run attached or it crashes.
    -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
    detached = vim.fn.has 'win32' == 0,
  },
  tests = {
    -- Applies to debug_test() and debug_last_test() only.
    verbose = true,
  },
}

-- The predefined test launch configurations ignore `tests.verbose`.
for _, config in ipairs(dap.configurations.go or {}) do
  if config.mode == 'test' and config.args == nil then config.args = { '-test.v' } end
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('kickstart-dap-go', { clear = true }),
  pattern = 'go',
  callback = function(event)
    vim.keymap.set('n', '<leader>rt', function() require('dap-go').debug_test() end, { buffer = event.buf, desc = 'Debug: [R]un nearest [T]est' })
  end,
})
