# 🐧 Personal Linux Environment & Dotfiles

> Personal Linux workstation configuration, shell environment, and developer tooling optimized for high-performance terminal workflows and AI agent orchestration.

---

## ⚡ Core Tools

Rather than holding project-specific build artifacts, this repository maintains the core personal environment and system tooling:

| Component | Tool | Description |
| :--- | :--- | :--- |
| **Shell** | **ZShell (Zsh)** | Custom Zsh environment powered by Oh My Zsh, Starship prompt, syntax highlighting, and autosuggestions. |
| **Terminal Multiplexer** | **Herder (Herdr)** | Agent-aware, Rust-powered terminal multiplexer designed for orchestrating concurrent terminal sessions and AI coding agents. |
| **Code Editor** | **LazyVim (LazyWim / Neovim)** | High-extensibility Neovim IDE configured via LazyVim with full DAP debugging, LSP tooling, sharp UI aesthetics, and auto-syncing. |

---

## 🖥️ Environment Stack & Features

### 1. ZShell (`.zshrc`)
* **Prompt & Theme**: Integrated with [Starship](https://starship.rs/) prompt for fast, informative, and minimal shell rendering (`starship init zsh`).
* **Framework**: Powered by [Oh My Zsh](https://ohmyz.sh/) with the `robbyrussell` theme baseline.
* **Productivity Plugins**:
  * `fast-syntax-highlighting` & `zsh-autosuggestions`
  * `zoxide` – smarter directory navigation (`z`)
  * `you-should-use` – reminders for existing aliases
  * `git` & `sudo`
* **Fuzzy Navigation**: Interactive fuzzy matching via `fzf` (`~/.fzf.zsh`).
* **Runtime Managers**:
  * **NVM** (Node Version Manager)
  * **PNPM** package manager environment
  * **SDKMAN** (Java / JVM manager)
  * **Go** toolchain paths (`$HOME/.go/bin`, `$HOME/go/bin`)

### 2. Herder / Herdr Terminal Multiplexer
* **Agent Awareness**: Built specifically for modern multi-agent development, providing native tracking of AI agent states (*working*, *blocked*, *idle*, *done*) across active sessions.
* **Persistent Sessions**: Detachable client/server architecture with lightweight Unix domain socket communication (`herdr.sock`).
* **Multi-Pane & Workspaces**: Structured tabs, pane splitting, and workspace grouping tailored for parallel coding and monitoring tasks.
* **Configuration**: Managed in `~/.config/herdr/config.toml`.

### 3. LazyVim Editor (`nvim/`)
Modern Neovim setup structured on top of [LazyVim](https://lazyvim.github.io/):
* **Aesthetic Theme**: Ayu Dark (`neovim-ayu`) with a sleek matte background.
* **Sharp Box UI**: Consistent single-line borders (`vim.g.border = "single"`) across LSP floating diagnostics, Mason UI, and Which-Key panels.
* **Custom Dashboard**: Minimalist `mini.starter` welcome screen featuring custom ASCII headers.
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

## ⚡ Aliases & Quick Commands (`.bash_aliases`)

Shared shell aliases loaded by Zsh:

```bash
alias cls='clear'

# Headless AI agent shortcuts (OpenCode)
alias opp='opencode run -c --auto -m openrouter/deepseek/deepseek-v4-flash-0731'
alias opd='opencode run -c --auto -m opencode/deepseek-v4-flash-free'
```

---

## 📂 Repository Structure

```text
dotfiles/
├── .agents/
│   └── skills/               # Reusable AI agent workflow skills
├── .bash_aliases             # General shell & AI CLI aliases
├── .zshrc                    # Main Zsh configuration, plugins & environment exports
├── nvim/                     # Complete LazyVim / Neovim configuration
│   ├── init.lua              # Neovim entry point
│   ├── lazyvim.json          # LazyVim extra plugins & profile config
│   ├── lazy-lock.json        # Pinned plugin lockfile
│   └── lua/
│       ├── config/           # Core options, keymaps, and autocmds (with repo auto-sync)
│       └── plugins/          # UI, colorscheme, DAP, markdown, and lazygit plugins
└── README.md                 # Environment documentation
```

---

## 🚀 Setup & Installation

### 1. Clone the Repository
```bash
git clone https://github.com/oshanavishkapiries/dotfiles.git ~/Projects/dotfiles
```

### 2. Configure ZShell
Symlink or source the `.zshrc` and `.bash_aliases` in your home directory:
```bash
ln -sf ~/Projects/dotfiles/.zshrc ~/.zshrc
ln -sf ~/Projects/dotfiles/.bash_aliases ~/.bash_aliases
```

Make sure prerequisites are installed:
```bash
# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install Starship prompt
curl -sS https://starship.rs/install.sh | sh
```

### 3. Install & Launch Herder (Herdr)
Install the Herdr terminal multiplexer:
```bash
curl -fsSL https://herdr.dev/install.sh | sh
```
Start or attach to a session:
```bash
herdr
```

### 4. Configure LazyVim (Neovim)
Symlink the repository's `nvim` folder to `~/.config/nvim`:
```bash
ln -sf ~/Projects/dotfiles/nvim ~/.config/nvim
```
Launch Neovim to allow `lazy.nvim` to bootstrap plugins automatically:
 ``bash
nvim
```
*Note: Any edits made to your `~/.config/nvim` configuration files will automatically sync back to `~/Projects/dotfiles/nvim/` whenever saved.*
