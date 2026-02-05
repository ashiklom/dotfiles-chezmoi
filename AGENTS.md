# Chezmoi Dotfiles Repository - Agent Guidelines

This repository manages dotfiles using [chezmoi](https://www.chezmoi.io/), a dotfile manager that uses templates to support multiple machines and operating systems.

## Repository Overview

- **Purpose**: Personal dotfiles synchronized across macOS, Linux, and WSL environments
- **Tool**: chezmoi v2.67.0+
- **Source Directory**: `~/.local/share/chezmoi`
- **Target Directory**: `~` (user home directory)
- **Repository**: github.com/ashiklom/dotfiles-chezmoi
- **License**: UNLICENSE (public domain)

## Chezmoi Commands

### Essential Operations

```bash
# Apply changes (copy templates to home directory)
chezmoi apply --init

# Apply specific file
chezmoi apply --init ~/.zshrc

# Apply changes (force redownload external)
chezmoi apply --init -R

# Show differences between source and target
chezmoi diff

# Edit a file in the source directory
chezmoi edit ~/.zshrc

# Add a new file to chezmoi management
chezmoi add ~/.newconfig

# Re-add an existing file (after manual edits)
chezmoi re-add ~/.zshrc

# Check repository health
chezmoi doctor

# Verify what would be applied
chezmoi apply --dry-run --verbose

# Update from git repository
chezmoi update
```

### Working with Templates

- Template files end with `.tmpl` extension
- Templates use Go template syntax (with sprig string functions)
- Test template rendering: `chezmoi execute-template < file.tmpl`
- View rendered output: `chezmoi cat ~/.zshrc`

## File Naming Conventions

Chezmoi uses special prefixes for file naming in the source directory:

- `dot_` → `.` (hidden files)
- `executable_` → executable permission
- `.tmpl` suffix → Go template (variables substituted)
- `private_` → permissions 0600
- `readonly_` → read-only files

Examples:
- `dot_zshrc.tmpl` → `~/.zshrc` (templated)
- `dot_config/` → `~/.config/`
- `dot_bash_aliases.tmpl` → `~/.bash_aliases`

## Template Variables

Available in `.chezmoi.yaml.tmpl` and all templates:

```go
{{ .chezmoi.os }}              // "darwin", "linux"
{{ .chezmoi.homeDir }}         // user home directory
{{ .is_macos }}                // boolean: macOS detection
{{ .is_linux }}                // boolean: Linux detection
{{ .is_wsl }}                  // boolean: WSL detection
{{ .is_nasa }}                 // boolean: NASA network detection
{{ .colors.* }}                // Catppuccin Mocha color palette
```

## External files and folders

Configured in `.chezmoiexternal.toml`.

Example: Include subdirectory `skills/skill-creator` from `https://github.com/anthropics/skills` repo.

```toml
[".agents/skills/skill-creator"]
type = "archive"
url = "https://github.com/anthropics/skills/archive/main.tar.gz"
exact = true
refreshPeriod = "672h"
include = ["*/skills/skill-creator/**"]
stripComponents = 3
```

Note that `include` filters are applied first to filter the archive file list (so all `include` filters should start with `*` or `**`); then `stripComponents` shortens the resulting matched files.

## Code Style Guidelines

### All template files (`.tmpl`)

- Include vim modeline for proper filetype detection; e.g. `# vim: filetype=yaml :`
- **system-specific**: use chezmoi template conditionals for system-specific config

### Shell Scripts (Bash/Zsh)

- **Shebang**: Use `#!/usr/bin/env zsh` or `#!/usr/bin/env bash` for shell-specific scripts or `#!/usr/bin/sh` for generic scripts
- **Style**: Follow standard shell conventions
- Define functions and aliases in `dot_bash_aliases.tmpl`. Prefer functions to aliases.

### Lua (WezTerm)

- **Indentation**: 2 spaces
- **Style**: Standard Lua conventions. Remember `local` for local variables.

### Python (IPython)

- **Config style**: Use IPython configuration API

### R

- lintr config at `~/.config/R/lintr/config` based on `linters_with_defaults()`

### YAML

- **Indentation**: 2 spaces
- **Comments**: Document template variables

## Git Workflow

- Use concise and descriptive commit messages

### File Modifications

- **Always edit source files**, not target files in `~`
- Use `chezmoi edit` or edit files directly in `~/.local/share/chezmoi`
- Never edit rendered files in home directory directly

### Testing Changes

Before committing:
1. Test template rendering: `chezmoi apply --dry-run --verbose`
2. Check for syntax errors in templates
3. Verify platform-specific conditionals work
4. Use `chezmoi diff` to review changes

## Platform-Specific Considerations

### macOS (is_macos)
- Uses Homebrew (`/opt/homebrew/bin/`)
- Special paths for WezTerm.app
- GNU utilities prefixed with `g` (gdircolors)

### Linux (is_linux)
- Assume Arch Linux
- Standard Unix paths
- Direct tool access without prefixes

### WSL (is_wsl)
- Hybrid Windows/Linux environment
- Assume Arch Linux
- Special handling for Windows interop (`/mnt/c/`)
- Custom `open` and `wezterm` wrapper functions

### NASA Network (is_nasa)
- Different git email configuration
- AWS/Azure authentication helpers
- PIV/SmartCard authentication (combined with `is_macos`)

## Common Tasks

### Adding a New Config File

```bash
# Create/edit the file in home directory first
nvim ~/.newconfig

# Add to chezmoi (will auto-detect if template needed)
chezmoi add ~/.newconfig

# If it needs templating, rename in source dir
mv ~/.local/share/chezmoi/dot_newconfig ~/.local/share/chezmoi/dot_newconfig.tmpl

# Edit to add template variables
chezmoi edit ~/.newconfig
```

### Updating Existing Config

```bash
# Method 1: Edit source directly
chezmoi edit ~/.zshrc
chezmoi apply --init

# Method 2: Edit target, then sync back
nvim ~/.zshrc
chezmoi re-add ~/.zshrc
```

### Synchronizing Across Machines

```bash
# On machine A (after changes)
cd ~/.local/share/chezmoi
git add . && git commit -m "update configs" && git push

# On machine B
chezmoi update  # Pulls and applies in one command
```

## Error Handling

- Template errors will prevent application - test with `chezmoi apply --dry-run`
- Use `chezmoi doctor` to diagnose configuration issues
- Check git status in source dir: `chezmoi cd` then `git status`
- View chezmoi logs with `--verbose` flag

## Tools and Integrations

This dotfiles setup integrates with:
- **Zsh**: zim framework, fzf, syntax highlighting
- **WezTerm**: Terminal emulator with Lua config
- **Git**: GitHub CLI integration, credential helpers
- **IPython**: Custom completions and styling
- **R**: lintr configuration
- **Cloud**: AWS SSO, Azure CLI helpers
- **Development**: NVM, Spack, various language tools

## Notes for AI Coding Agents

1. **Always check if changes require templating** - Look for OS-specific logic
2. **Never modify files in `~` directly** - Edit source in `~/.local/share/chezmoi`
3. **Test before applying** - Use dry-run mode
4. **Respect platform boundaries** - Use appropriate template conditionals
5. **Preserve existing patterns** - Follow established conventions in the repo
6. **Document template variables** - Comment complex template logic
7. **Verify vim filetype hints** - Maintain footer comments for editor detection
