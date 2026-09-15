-- Starts (or attaches to) eclipse.jdt.ls for every Java buffer, via nvim-jdtls.
--
-- The root is the git root, not the nearest pom.xml: the modersys repos hold several
-- independent Maven trees in one repository (standalone projects plus aggregators whose
-- modules live outside the aggregator's own directory), so a single workspace per repo
-- lets the Maven importer pick up every project and resolve cross-project references
-- in-editor.
local root = vim.fs.root(0, { '.git' }) or vim.fn.getcwd()

local mason_jdtls = vim.fn.stdpath 'data' .. '/mason/packages/jdtls'
local launcher = vim.fn.glob(mason_jdtls .. '/plugins/org.eclipse.equinox.launcher_*.jar', true, true)[1]
if not launcher then
  vim.notify('jdtls is not installed yet (mason installs it on startup; or run :MasonInstall jdtls)', vim.log.levels.WARN)
  return
end

local sysname = vim.loop.os_uname().sysname
local jdtls_config_dir
if sysname == 'Windows_NT' then
  jdtls_config_dir = mason_jdtls .. '/config_win'
elseif sysname == 'Darwin' then
  jdtls_config_dir = mason_jdtls .. '/config_mac'
else
  jdtls_config_dir = mason_jdtls .. '/config_linux'
end

-- One workspace dir per repo, kept outside the repo so it never shows up in git.
local ws = vim.fn.stdpath 'data' .. '/jdtls-ws/' .. (vim.fn.fnamemodify(root, ':p'):gsub('[:\\/]', '_'))

-- Raw java invocation instead of mason's jdtls shim: the shim goes through a Python
-- launcher, and the JVM flags here need to land on the server process itself.
local cmd = {
  'java',
  '-Declipse.application=org.eclipse.jdt.ls.core.id1',
  '-Dosgi.bundles.defaultStartLevel=4',
  '-Declipse.product=org.eclipse.jdt.ls.core.product',
  '-Dlog.protocol=true',
  '-Dlog.level=ALL',
  '-Xmx2g',
  '--add-modules=ALL-SYSTEM',
  '--add-opens', 'java.base/java.util=ALL-UNNAMED',
  '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
}

if sysname == 'Windows_NT' then
  -- Maven dependency resolution runs inside this JVM (m2e), which MAVEN_OPTS does not
  -- reach. The corporate TLS-interception CA lives in the Windows cert store, so
  -- artifact downloads fail PKIX validation against the JDK's own cacerts without this.
  table.insert(cmd, '-Djavax.net.ssl.trustStoreType=WINDOWS-ROOT')
end

vim.list_extend(cmd, {
  '-jar', launcher,
  '-configuration', jdtls_config_dir,
  '-data', ws,
})

require('jdtls').start_or_attach {
  cmd = cmd,
  root_dir = root,
}
