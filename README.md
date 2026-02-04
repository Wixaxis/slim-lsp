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

```bash
bundle install
npm install
```

## Run

```bash
bin/slim-lsp
```

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

## Neovim (lazy.nvim)

```lua
{
  "neovim/nvim-lspconfig",
  dependencies = {},
  config = function()
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
  end
}
```

## Install From GitHub

```bash
git clone https://github.com/<your-user>/slim-lsp.git
cd slim-lsp
bundle install
npm install
```

## What It Does

### Diagnostics

On every open/change, the server runs Slim's parser to catch syntax errors and publishes diagnostics.

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
