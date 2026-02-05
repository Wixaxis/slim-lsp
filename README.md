# slim-lsp

A small Ruby-based LSP server for Slim templates. It focuses on:

- Syntax diagnostics using Slim's own parser
- Tailwind class sorting for `class="..."` / `class='...'` attributes
- Basic completions for HTML tags and common Slim keywords

## Requirements

- Ruby 3.1+
- Node.js 18+ (only for Tailwind class sorting)
- `bundler`

## Install

You can use it in two ways:

### 1) As a local clone (recommended during development)

```bash
bundle config set path 'vendor/bundle'
bundle install
npm install
```

### 2) As a gem from a git repo

```bash
gem install specific_install
gem specific_install https://github.com/Wixaxis/slim-lsp.git
```

#### Tailwind sorting when installed as a gem

Tailwind class sorting requires a Node dependency. RubyGems does not run `npm install`,
so you need one extra step:

```bash
gem which slim_lsp
```

That will show the gem path. Then:

```bash
cd /path/to/gem
npm install
```

If you skip this step, the LSP still works, but class sorting is disabled.

### Bundler install from Git (for Ruby projects)

```ruby
gem 'slim_lsp', git: 'https://github.com/Wixaxis/slim-lsp.git'
```

### Bundler 4 Note

Bundler 4 removed the `--path` flag. If you're using Bundler 4 (or a Ruby
version manager like mise), run `bundle config set path 'vendor/bundle'`
before `bundle install`.

### mise Ruby (Recommended if you use mise)

If you use mise to manage Ruby, run the installs through mise so the gems land
in the same Ruby version your editor will use:

```bash
mise exec ruby -- bundle _4.0.1_ config set path 'vendor/bundle'
mise exec ruby -- bundle _4.0.1_ install
```

## Run

```bash
slim-lsp
```

## CLI

Format a file (stdout):

```bash
slim-lsp --format path/to/file.slim
```

Format from stdin:

```bash
cat path/to/file.slim | slim-lsp --format -
```

Format and overwrite:

```bash
slim-lsp --format path/to/file.slim --write
```

Check if formatting is needed (exit 1 on diff):

```bash
slim-lsp --format path/to/file.slim --check
```

Diagnose syntax errors:

```bash
slim-lsp --diagnose path/to/file.slim
```

Example for CI (fail on formatting changes):

```bash
slim-lsp --format path/to/file.slim --check
```

Tailwind options for CLI:

```bash
slim-lsp --format path/to/file.slim --tailwind-config tailwind.config.js --tailwind-stylesheet app/assets/stylesheets/application.tailwind.css
```

## Tests

```bash
bundle exec ruby -Itest test/*_test.rb
```

### Test Fixtures

Formatter fixtures live in `test/fixtures/format/` and include input/expected Slim templates.
Diagnostics fixtures live in `test/fixtures/diagnostics/`.

## Neovim (nvim-lspconfig)

```lua
local lspconfig = require("lspconfig")

lspconfig.slim_lsp = {
  default_config = {
    cmd = {"/absolute/path/to/slim-lsp/bin/slim-lsp"},
    filetypes = {"slim"},
    root_dir = lspconfig.util.root_pattern("Gemfile", ".git"),
    settings = {
      tailwind = {
        enabled = true,
        configPath = "tailwind.config.js",
        stylesheetPath = "app/assets/stylesheets/application.tailwind.css",
        preserveDuplicates = false,
        preserveWhitespace = true,
        nodePath = "node"
      },
      completion = {
        enabled = true
      }
    }
  }
}

lspconfig.slim_lsp.setup({})
```

### Neovim Setup Steps

1. Ensure you have `nvim-lspconfig` installed.
2. Install Ruby and Node dependencies:
   - `bundle install`
   - `npm install`
3. Replace `/absolute/path/to/slim-lsp` with the real path to this repo.
4. Restart Neovim and open a `.slim` file.

### Neovim (built-in `vim.lsp.config`)

If you're using Neovim's built-in LSP config (0.11+), you can register and
enable the server without `lspconfig`:

```lua
local config_root = vim.fn.stdpath('config')

vim.lsp.config('slim_lsp', {
  cmd = { 'slim-lsp' },
  filetypes = { 'slim' },
  root_dir = function(bufnr)
    return vim.fs.root(bufnr, { 'Gemfile', '.git' }) or vim.fn.getcwd()
  end,
  autostart = true,
})

if vim.lsp.enable then vim.lsp.enable('slim_lsp') end
```

## Neovim (lazy.nvim)

```lua
{
  "neovim/nvim-lspconfig",
  dependencies = {},
  config = function()
    local lspconfig = require("lspconfig")
    lspconfig.slim_lsp = {
      default_config = {
        cmd = {"slim-lsp"},
        filetypes = {"slim"},
        root_dir = lspconfig.util.root_pattern("Gemfile", ".git"),
        settings = {
          tailwind = {
            enabled = true,
            configPath = "tailwind.config.js",
            stylesheetPath = "app/assets/stylesheets/application.tailwind.css",
            preserveDuplicates = false,
            preserveWhitespace = true,
            nodePath = "node"
          },
          completion = {
            enabled = true
          }
        }
      }
    }

    lspconfig.slim_lsp.setup({})
  end
}
```

## Install From GitHub

```bash
git clone https://github.com/Wixaxis/slim-lsp.git
cd slim-lsp
bundle install
npm install
```

## Troubleshooting

### LSP doesn't start in Neovim

1. Confirm the server is registered and enabled:
   - `:LspInfo` should list `slim_lsp` under **Enabled Configurations**.
2. Confirm the executable runs:
   - `:lua print(vim.fn.executable('/absolute/path/to/slim-lsp/bin/slim-lsp'))`
3. Check the LSP log:
   - `:edit ~/.local/state/nvim/lsp.log`

### Bundler can't find gems

If you see `Bundler::GemNotFound` in the LSP log, the server is using a Ruby
that doesn't match where the gems were installed. Fix by installing with the
same Ruby your editor uses (e.g., `mise exec ruby -- bundle _4.0.1_ install`),
or by running the LSP with an explicit Ruby path.

## What It Does

### Diagnostics

On every open/change, the server runs Slim's parser to catch syntax errors and publishes diagnostics.
If `lint.enabled` is `true`, it will also run `slim-lint` and surface its offenses as diagnostics.

### Formatting (Tailwind class sort)

On `textDocument/formatting`, the server scans `class="..."` and `class='...'` attributes and sorts the class list using Tailwind's ordering rules.

### Completions

Returns a basic list of HTML tags plus a few Slim keywords (doctype, filters like `javascript:`, `css:`, etc.).

## Configuration

You can set configuration via `settings` (preferred) or `initializationOptions`.

```json
{
  "tailwind": {
    "enabled": true,
    "configPath": "tailwind.config.js",
    "stylesheetPath": "app/assets/stylesheets/application.tailwind.css",
    "preserveDuplicates": false,
    "preserveWhitespace": true,
    "nodePath": "node"
  },
  "lint": {
    "enabled": false,
    "command": "slim-lint",
    "useBundler": true,
    "reporter": "json",
    "configPath": ".slim-lint.yml",
    "includeLinters": [],
    "excludeLinters": [],
    "exclude": [],
    "extraArgs": []
  },
  "completion": {
    "enabled": true
  }
}
```

## Notes

- Only quoted `class` attributes are sorted for now. Slim shorthand classes (like `.btn.btn-primary`) are not yet sorted.
- Formatting is intentionally minimal; it only reorders Tailwind classes rather than reprinting the whole template.

## Next Ideas

- Handle Slim shorthand classes (`.foo.bar`) and dynamic class bindings.
- Incremental diagnostics and smarter completions.
- Optional tree-sitter based structure hints for better diagnostics.
- Optional slim-lint integration for richer linting rules.
