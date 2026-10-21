# 🐧 Personal Linux Environment & Dotfiles

> Personal Linux workstation configuration, shell environment, and developer tooling optimized for high-performance terminal workflows and AI agent orchestration.

---

## ⚡ Core Tools

Rather than holding project-specific build artifacts, this repository maintains the core personal environment and system tooling:

| Component | Tool | Description |
| :--- | :--- | :--- |
| **Shell** | **ZShell (Zsh)** | Custom Zsh environment powered by Oh My Zsh, Starship prompt, syntax highlighting, and autosuggestions. |
| **Terminal Multiplexer** | **Herdr** | Agent-aware, Rust-powered terminal multiplexer designed for orchestrating concurrent terminal sessions and AI coding agents. |
| **Code Editor** | **LazyVim (Neovim)** | High-extensibility Neovim IDE configured via LazyVim with full DAP debugging, LSP tooling, sharp UI aesthetics, and auto-syncing. |

---

## 🖥️ Environment Stack & Features

### 1. Starship Prompt (`starship.toml`)
* **Theme**: [Catppuccin Powerline](https://starship.rs/presets/catppuccin-powerline) preset with coloured arrow segments for OS, user, directory, git, language runtimes and time.
* **Two-line prompt**: `[line_break]` is enabled so commands are typed on a second line under the `❯` arrow.
* **Requires**: [Starship](https://starship.rs/) and a Nerd Font (e.g. JetBrainsMono Nerd Font).

### 2. Herdr Terminal Multiplexer
* **Agent Awareness**: Built specifically for modern multi-agent development, providing native tracking of AI agent states (*working*, *blocked*, *idle*, *done*) across active sessions.
* **Persistent Sessions**: Detachable client/server architecture with lightweight Unix domain socket communication (`herdr.sock`).
* **Multi-Pane & Workspaces**: Structured tabs, pane splitting, and workspace grouping tailored for parallel coding and monitoring tasks.
* **Configuration**: Managed in `~/.config/herdr/config.toml`.

### 3. LazyVim Editor (`nvim/`)
Modern Neovim setup structured on top of [LazyVim](https://lazyvim.github.io/):
* **Aesthetic Theme**: Catppuccin Mocha with a transparent background.
* **Sharp Box UI**: Consistent single-line borders (`vim.g.border = "single"`) across LSP floating diagnostics, Mason UI, and Which-Key panels.
* **Dashboard**: Minimal `snacks.nvim` dashboard with just a key menu (find file, recent files, lazygit, restore session, quit).
* **Statusline**: Includes system stats (`sysinfo.lua`).
* **File Management**: `oil.nvim` for editing local directories (`-`, `<leader>ol`) and remote ones over SSH on host `LAB1` (`<leader>or`, `<leader>oR`).
* **Git Tools**: Inline blame via `gitsigns.nvim`, and `diffview.nvim` for diffs and file history (`<leader>gd`, `<leader>gD`, `<leader>gh`).
* **TODO Comments**: `todo-comments.nvim` highlighting and search.
* **Debugging (DAP)**: Comprehensive Debug Adapter Protocol setup via `nvim-dap`, `nvim-dap-ui`, and `nvim-dap-virtual-text` supporting Go, Python, Java, JavaScript, and TypeScript.
* **Git Integration**: Fast floating terminal interface powered by `lazygit.nvim` (`<leader>gg` / `<leader>lg`).
* **Documentation & Markdown**: Live previewing via `markdown-preview.nvim` and ToggleTerm markdown utilities (`<leader>mp`).
* **Remote Clipboard**: Built-in OSC 52 provider support for smooth system clipboard operations over SSH sessions.
* **Auto-Sync Hook**: Custom `BufWritePost` autocmd that automatically rsyncs edits made in `~/.config/nvim/` back into this dotfiles repository upon saving.

---

## 🤖 Agentic Tooling & Skills (`.agents/skills/`)

This environment is augmented with agentic workflow skills used for planning, code reviews, and autonomous coding tasks:

* **`code-review`**: Parallel dual-axis review checking both repository coding standards and original specification requirements.
* **`codebase-doc-mapper`**: Generates navigable, interlinked markdown documentation maps and dependency diagrams for codebases.
* **`grill-me` / `grilling`**: Interactive stress-testing sessions to challenge designs, specifications, and architecture decisions.
* **`prototype`**: Rapid throwaway prototyping for validating state models, architecture logic, and UI ideas.
* **`to-spec` / `to-tickets`**: Translates user goals and features into formal specifications and granular task tickets.
* **`implement-spec` / `handoff`**: Systematic execution workflows and context preservation across development sessions.

---

## 📂 Repository Structure

```text
dotfiles/
├── .agents/
│   └── skills/               # Reusable AI agent workflow skills
├── .zshrc                    # Zsh config (Oh My Zsh, plugins, NVM, SDKMAN, Starship)
├── .bash_aliases             # Shell aliases (cls, opp, opd), sourced by .zshrc
├── Bash/                     # Session cleanup scripts (Claude, Codex, Antigravity)
├── starship.toml             # Starship prompt config (Catppuccin Powerline)
├── nvim/                     # Complete LazyVim / Neovim configuration
│   ├── init.lua              # Neovim entry point
│   ├── lazyvim.json          # LazyVim extra plugins & profile config
│   ├── lazy-lock.json        # Pinned plugin lockfile
│   └── lua/
│       ├── config/           # Core options, keymaps, and autocmds (with repo auto-sync)
│       └── plugins/          # UI, colorscheme, dashboard, DAP, oil, git, markdown plugins
└── README.md                 # Environment documentation
```

---

## 🚀 Setup & Installation

### 1. Clone the Repository
```bash
git clone https://github.com/oshanavishkapiries/dotfiles.git ~/Projects/dotfiles
```

### 2. Link Zsh Files
```bash
ln -sf ~/Projects/dotfiles/.zshrc ~/.zshrc
ln -sf ~/Projects/dotfiles/.bash_aliases ~/.bash_aliases
```

### 3. Configure Starship
```bash
# Install Starship prompt
curl -sS https://starship.rs/install.sh | sh

# Link the config
ln -sf ~/Projects/dotfiles/starship.toml ~/.config/starship.toml
```
Add `eval "$(starship init zsh)"` to your `~/.zshrc` and set your terminal font to a Nerd Font.

### 4. Install & Launch Herdr
Install the Herdr terminal multiplexer:
```bash
curl -fsSL https://herdr.dev/install.sh | sh
```
Start or attach to a session:
```bash
herdr
```

### 5. Configure LazyVim (Neovim)
Symlink the repository's `nvim` folder to `~/.config/nvim`:
```bash
ln -sf ~/Projects/dotfiles/nvim ~/.config/nvim
```
Launch Neovim to allow `lazy.nvim` to bootstrap plugins automatically:
```bash
nvim
```
*Note: Any edits made to your `~/.config/nvim` configuration files will automatically sync back to `~/Projects/dotfiles/nvim/` whenever saved.*
