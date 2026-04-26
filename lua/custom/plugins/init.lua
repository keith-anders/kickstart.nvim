-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

-- Iterate over all Lua files in the plugins directory and load them
local plugins_dir = vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', 'custom', 'plugins')
for file_name, type in vim.fs.dir(plugins_dir, { follow = true }) do
  if (type == 'file' or type == 'link') and file_name:match '%.lua$' and file_name ~= 'init.lua' then
    local module = file_name:gsub('%.lua$', '')
    require('custom.plugins.' .. module)
  end
end

vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4

vim.keymap.set('n', '<leader>wj', ':sp<CR>', { desc = 'Split [W]indow [j]Down' })
vim.keymap.set('n', '<leader>wJ', ':sp +:terminal<CR>', { desc = 'Split [W]indow [J]Down Terminal' })

vim.keymap.set('n', '<leader>wl', ':vs<CR>', { desc = 'Split [W]indow [l]Right' })
vim.keymap.set('n', '<leader>wL', ':vs +:terminal<CR>', { desc = 'Split [W]indow [L]Right Terminal' })

vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
  pattern = { '*.component.html' },
  callback = function() vim.treesitter.start(nil, 'angular') end,
})

if vim.loop.os_uname().sysname == 'Windows_NT' then
  vim.o.shell = 'powershell.exe'
  vim.o.shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command '
    .. '[Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new();'
    .. "$PSDefaultParameterValues['Out-File:Encoding']='utf8';"
    .. 'Remove-Item Alias:tee -Force -ErrorAction SilentlyContinue;'
    .. 'Remove-Item Alias:curl -Force -ErrorAction SilentlyContinue;'
    .. 'Remove-Item Alias:wget -Force -ErrorAction SilentlyContinue;'
  vim.o.shellredir = '2>&1 | %%{ "$_" } | Out-File %s; exit $LastExitCode'
  vim.o.shellpipe = '2>&1 | %%{ "$_" } | tee %s; exit $LastExitCode'
  vim.o.shellquote = ''
  vim.o.shellxquote = ''
else
  vim.o.shell = 'bash'
end

vim.keymap.set('n', '<leader>p', ':bp<CR>')
vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
  pattern = { '*.component.html' },
  callback = function() vim.treesitter.start(nil, 'angular') end,
})

-- let &shellcmdflag = '-NoLogo -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new();$PSDefaultParameterValues[''Out-File:Encoding'']=''utf8'';Remove-Alias -Force -ErrorAction SilentlyContinue tee;'
-- let &shellredir = '2>&1 | %%{ "$_" } | Out-File %s; exit $LastExitCode'
-- let &shellpipe  = '2>&1 | %%{ "$_" } | tee %s; exit $LastExitCode'
-- set shellquote= shellxquote=

-- [[ Custom plugins (migrated from lazy.nvim spec to vim.pack) ]]
--  These were previously returned as a LazySpec table. Under the new `vim.pack`
--  setup in init.lua that return value is ignored, so each plugin is now added
--  and configured explicitly. This file is required at the end of init.lua, so
--  shared deps already added earlier (plenary, nvim-lspconfig) are available.
local function gh(repo) return 'https://github.com/' .. repo end

-- Motion plugin (vimscript, no setup needed)
vim.pack.add { gh 'justinmk/vim-sneak' }

-- Automatic session management
vim.pack.add { gh 'rmagatti/auto-session' }
require('auto-session').setup {
  -- allowed_dirs = { 'D:\\src\\pharma\\full', 'D:\\src\\pharma\\full\\*', 'D:\\src\\pharma\\full\\*\\*' },
  suppressed_dirs = {},
  -- Close neo-tree before saving so it isn't restored (and auto-opened) on next launch.
  pre_save_cmds = { 'Neotree close' },
}

-- TypeScript / Angular language server (this is what serves intellisense in .ts files)
vim.pack.add { gh 'pmizio/typescript-tools.nvim' } -- plenary + nvim-lspconfig added earlier in init.lua
require('typescript-tools').setup {}

-- LazyGit integration. vim.pack has no lazy-loading, so the plugin loads at startup
-- and `:LazyGit` is available immediately; just bind the keymap.
vim.pack.add { gh 'kdheepak/lazygit.nvim' } -- plenary added earlier in init.lua
vim.keymap.set('n', '<leader>lg', '<cmd>LazyGit<CR>', { desc = 'LazyGit' })

-- C# language server (roslyn). Ports the old lazy `build` step to a PackChanged
-- hook so the server downloads on first install and re-downloads on update.
local function build_roslyn()
  local install_dir = vim.fn.stdpath 'data' .. '/roslyn'
  vim.fn.delete(install_dir, 'rf')
  vim.fn.mkdir(install_dir, 'p')

  local rid
  local sysname = vim.loop.os_uname().sysname
  if sysname == 'Windows_NT' then
    rid = 'win-x64'
  elseif sysname == 'Darwin' then
    rid = vim.loop.os_uname().machine == 'arm64' and 'osx-arm64' or 'osx-x64'
  else
    rid = 'linux-x64'
  end

  local ps_script = string.format(
    [[
      $ProgressPreference = 'SilentlyContinue';
      $headers = @{ 'User-Agent' = 'nvim-config' };
      $release = Invoke-RestMethod -Headers $headers 'https://api.github.com/repos/Crashdummyy/roslynLanguageServer/releases/latest';
      $asset = $release.assets | Where-Object { $_.name -like '*%s*' } | Select-Object -First 1;
      if (-not $asset) { throw 'No asset found for %s' }
      $zip = Join-Path $env:TEMP $asset.name;
      Invoke-WebRequest -Headers $headers $asset.browser_download_url -OutFile $zip;
      Expand-Archive -Force $zip '%s';
      Remove-Item $zip;
    ]],
    rid,
    rid,
    install_dir
  )

  if sysname == 'Windows_NT' then
    vim.fn.system { 'powershell', '-NoProfile', '-Command', ps_script }
  else
    -- Linux/macOS: use curl + unzip equivalent
    local sh_script = string.format(
      [[
        set -e
        rid="%s"
        latest=$(curl -s https://api.github.com/repos/Crashdummyy/roslynLanguageServer/releases/latest | grep tag_name | head -1 | cut -d '"' -f4)
        asset=$(curl -s "https://api.github.com/repos/Crashdummyy/roslynLanguageServer/releases/tags/$latest" | grep browser_download_url | grep "$rid" | head -1 | cut -d '"' -f4)
        curl -Lo /tmp/roslyn.zip "$asset"
        unzip -o /tmp/roslyn.zip -d "%s"
        rm /tmp/roslyn.zip
      ]],
      rid,
      install_dir
    )
    vim.fn.system { 'bash', '-c', sh_script }
  end
end

-- Register the build hook BEFORE adding the plugin so it fires on first install.
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    if ev.data.spec.name ~= 'roslyn.nvim' then return end
    if ev.data.kind ~= 'install' and ev.data.kind ~= 'update' then return end
    build_roslyn()
  end,
})

vim.pack.add { gh 'seblyng/roslyn.nvim' }
vim.lsp.config('roslyn', {
  cmd = {
    'dotnet',
    vim.fn.stdpath 'data' .. '/roslyn/Microsoft.CodeAnalysis.LanguageServer.dll',
    '--stdio',
  },
})
require('roslyn').setup {
  choose_target = function(targets)
    for _, target in ipairs(targets) do
      if target:match 'PharmaPortal%.sln$' then
        return target
      elseif target:match 'SmartFactoryRx%.sln$' then
        return target
      end
    end
    return targets[1]
  end,
}
