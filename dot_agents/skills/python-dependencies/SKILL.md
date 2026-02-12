---
name: python-dependencies
description: "Manage Python project dependencies using modern tools (uv and pixi). Use this skill when creating new Python projects, adding dependencies, setting up development environments, configuring IDE and agent integration, or working with standalone scripts. Covers: project initialization, dependency installation, environment selection (uv vs pixi), inline script dependencies (PEP 723), and IDE/agent/LSP configuration for pixi projects."
---

# Python Dependency Management

Modern Python dependency management using uv and pixi. This skill provides guidance on tool selection, project setup, dependency installation, and IDE configuration.

## Tool Selection

### New Projects: Ask User Preference

When starting a new Python project, **ask the user** which dependency management system to use:

**Recommended question:**
> "Would you like to use **pixi** or **uv** for this project?
> - **pixi**: Recommended for projects with complex system dependencies (GDAL, HDF5, NetCDF, scientific libraries, geospatial tools)
> - **uv**: Recommended for pure Python projects with PyPI-only dependencies"

### Existing Projects: Auto-Detect

```bash
# Detection logic
if [ -f "pixi.toml" ] || grep -q "\[tool.pixi\]" pyproject.toml 2>/dev/null; then
    # Use pixi
elif [ -f "pyproject.toml" ] || [ -f "uv.lock" ]; then
    # Use uv
else
    # Ask user
fi
```

## Project Initialization

When starting a new project from scratch, use the appropriate init command based on the chosen tool.

### Pixi: Initialize New Project

**Recommended: Use pyproject.toml format** (unless user explicitly requests pixi.toml)

```bash
# Initialize in current directory
pixi init --format pyproject

# Initialize in new directory
pixi init --format pyproject myproject
cd myproject

# Specify Python version immediately
pixi init --format pyproject
pixi add python=3.13
```

**What gets created:**
- `pyproject.toml` with `[tool.pixi.project]` section
- `.gitignore` (excludes `.pixi/` environment directory)
- `.gitattributes`
- **NOTE**: Pixi does NOT create example scripts or source files

**Initial structure:**
```
myproject/
├── pyproject.toml    # Project configuration
├── .gitignore
└── .gitattributes
```

**Minimal setup workflow:**
```bash
# 1. Create project
pixi init --format pyproject myproject
cd myproject

# 2. Add Python and core dependencies
pixi add python=3.13

# 3. Set up dev environment with LSP tools
pixi add --feature dev pytest black ruff pyright

# 4. Configure OpenCode LSP (see OpenCode section below)

# 5. Install environments
pixi install

# Ready to work!
```

### UV: Initialize New Project

UV offers multiple project types. Choose based on use case:

**Simple application (default - recommended for most projects):**
```bash
# Initialize in current directory
uv init

# Initialize in new directory
uv init myproject
cd myproject
```

**What gets created:**
- `pyproject.toml` (minimal, no build system)
- `main.py` (hello world example)
- `README.md`
- `.python-version` (pins Python version)

**To avoid example files**, there is **NO** flag to prevent `main.py` and `README.md` creation. You must delete them manually:

```bash
uv init myproject
cd myproject
rm main.py README.md  # Remove example files if not wanted
```

**Library project (for packages to distribute on PyPI):**
```bash
uv init --lib mypackage
cd mypackage
```

Creates `src/` layout with proper package structure and build system.

**Packaged application (CLI tools, installable apps):**
```bash
uv init --package mycli
cd mycli
```

Creates `src/` layout with entry point configuration for console scripts.

**Minimal setup workflow for application:**
```bash
# 1. Create project
uv init myproject
cd myproject

# 2. Remove example files (if desired)
rm main.py README.md

# 3. Add dependencies
uv add requests httpx

# 4. Add dev dependencies
uv add --dev pytest black ruff

# 5. Sync environment
uv sync

# Ready to work!
```

### Project Initialization Decision Tree

```
Starting new project from scratch?
│
├─ User chose pixi?
│  └─ Run: pixi init --format pyproject [name]
│     └─ Add Python: pixi add python=3.13
│     └─ Add dev tools: pixi add --feature dev pytest black ruff
│
├─ User chose uv?
│  ├─ Simple app/script?
│  │  └─ Run: uv init [name]
│  │     └─ Optional: rm main.py README.md
│  │
│  ├─ Library for PyPI?
│  │  └─ Run: uv init --lib [name]
│  │
│  └─ CLI tool/installable app?
│     └─ Run: uv init --package [name]
│
└─ User hasn't chosen?
   └─ ASK: "Would you like pixi (system deps) or uv (pure Python)?"
```

### Key Differences in Init Behavior

| Feature | Pixi | UV |
|---------|------|-----|
| Config file | pyproject.toml or pixi.toml | pyproject.toml |
| Example code | ❌ None created | ✅ Creates main.py |
| README | ❌ None created | ✅ Creates README.md |
| Python pin | ❌ Must add manually | ✅ Creates .python-version |
| Build system | ❌ Only if needed | Depends on --lib/--package flags |
| Minimal init | ✅ Already minimal | ❌ Must delete files manually |

### Post-Initialization Best Practices

**For Pixi projects:**
1. Immediately add Python version: `pixi add python=3.13`
2. Set up dev feature: `pixi add --feature dev <tools>`
3. Create `opencode.json` for LSP integration
4. Run `pixi install` to create environments

**For UV projects:**
1. Delete example files if not needed: `rm main.py README.md`
2. Add dependencies: `uv add <packages>`
3. Add dev dependencies: `uv add --dev <tools>`
4. Run `uv sync` to create environment

### Converting Existing Projects

**Add pixi to existing Python project:**
```bash
# If you have pyproject.toml
pixi init  # Adds [tool.pixi.project] section

# If starting fresh
pixi init --format pyproject
# Manually add your project metadata to [project] section
```

**Add uv to existing project:**
```bash
# uv works with existing pyproject.toml
uv sync  # Reads existing pyproject.toml and creates lock file
```

## Pixi Projects

### Project Structure

Pixi uses **features** and **environments** to organize dependencies:

- **Features**: Named groups of dependencies (similar to dependency groups in pyproject.toml)
- **Environments**: Combinations of features that create isolated environments
- **Default environment**: Built from dependencies in `[dependencies]` section

### Adding Dependencies

```bash
# Add runtime dependency (defaults to conda-forge, auto-falls back to PyPI)
pixi add numpy

# Add to a specific feature
pixi add --feature dev pytest black ruff

# Add to a specific feature (alternative syntax)
pixi add --feature test pytest pytest-cov

# Explicitly add from PyPI
pixi add --pypi polars

# Add from specific conda channel
pixi add --channel conda-forge gdal
```

**CRITICAL**: Use features, NOT `--dev` flag (which doesn't exist in pixi)

### Setting Up Development Environment

**Standard pattern** for pixi projects:

```toml
# pixi.toml or pyproject.toml with [tool.pixi]

[dependencies]
# Runtime dependencies - always installed
python = ">=3.13"
numpy = "*"

[feature.dev.dependencies]
# Development tools
pytest = "*"
black = "*"
ruff = "*"
mypy = "*"

[feature.dev.pypi-dependencies]
# PyPI-only dev dependencies
pre-commit = "*"

[environments]
# Default environment: just runtime deps
default = []

# Dev environment: runtime + dev deps  
dev = ["dev"]
```

Add dev dependencies:
```bash
pixi add --feature dev pytest black ruff mypy
```

### Creating Environments

```bash
# Create/activate environments (happens automatically with pixi install)
pixi install

# Run command in specific environment
pixi run --environment dev pytest
pixi run --environment default python script.py

# Enter shell with specific environment
pixi shell --environment dev
```

### OpenCode LSP Integration for Pixi

When using pixi projects with OpenCode, configure LSP servers to run inside the pixi environment. This ensures type checking, linting, and other language features use the correct Python interpreter and installed packages.

**Create `opencode.json` in project root:**

```json
{
  "$schema": "https://opencode.ai/config.json",
  "lsp": {
    "pyright": {
      "command": ["pixi", "run", "--environment", "dev", "pyright-langserver", "--stdio"],
      "extensions": [".py", ".pyi"]
    },
    "ruff": {
      "command": ["pixi", "run", "--environment", "dev", "ruff", "server"],
      "extensions": [".py", ".pyi"]
    }
  }
}
```

**Key points:**
- LSP servers run via `pixi run --environment dev` to use the dev environment
- Install LSP tools in the `dev` feature (not default environment)
- OpenCode automatically starts LSP servers when opening Python files
- Multiple LSP servers can run simultaneously (pyright for type checking, ruff for linting)

**Full setup workflow:**

```bash
# 1. Create pixi project
pixi init --format pyproject

# 2. Add runtime dependencies
pixi add python=3.13 numpy polars

# 3. Add LSP tools to dev feature
pixi add --feature dev pyright ruff-lsp

# 4. Create opencode.json (see above)

# 5. Install environments
pixi install

# 6. OpenCode will now use pixi-installed LSP servers
```

**Alternative: Using basedpyright**

For projects preferring basedpyright over pyright:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "lsp": {
    "basedpyright": {
      "command": ["pixi", "run", "--environment", "dev", "basedpyright-langserver", "--stdio"],
      "extensions": [".py", ".pyi"]
    }
  }
}
```

```bash
# Add basedpyright to dev feature
pixi add --feature dev basedpyright
```

## UV Projects

### Adding Dependencies

```bash
# Add runtime dependency
uv add numpy

# Add development dependency
uv add --dev pytest black ruff

# Add with version constraint
uv add "polars>=1.0,<2.0"

# Add optional dependency group
uv add --optional docs sphinx sphinx-rtd-theme
```

### Installing Dependencies

```bash
# Sync environment with lock file
uv sync

# Install with dev dependencies
uv sync --dev

# Install specific groups
uv sync --group docs
```

### Running Commands

```bash
# Run in uv environment
uv run python script.py
uv run pytest

# Run without installing project
uv run --no-project python script.py
```

## Standalone Scripts with Inline Dependencies

For **one-off scripts and tools**, use uv with PEP 723 inline script metadata.

### Basic Pattern

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "requests>=2.31",
#     "rich",
# ]
# ///

import requests
from rich import print

response = requests.get("https://api.github.com")
print(response.json())
```

### When to Use Inline Scripts

**Use inline script dependencies for:**
- One-off automation scripts
- Utility tools
- Quick prototypes
- Scripts shared with colleagues
- CLI tools that should "just work"

**Don't use for:**
- Large projects with multiple files
- Libraries you'll distribute on PyPI
- Projects with complex build requirements

### Creating Inline Scripts

```bash
# Add dependencies to existing script
uv add --script myscript.py requests rich

# This modifies the script header:
# /// script
# dependencies = [
#     "requests",
#     "rich",
# ]
# ///
```

### Running Inline Scripts

```bash
# Run directly
uv run myscript.py

# Make executable with shebang
chmod +x myscript.py
./myscript.py

# Lock for reproducibility
uv lock --script myscript.py
# Creates myscript.py.lock
```

### Shebang Pattern

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.13"
# dependencies = ["httpx", "typer"]
# ///

import typer
import httpx

app = typer.Typer()

@app.command()
def fetch(url: str):
    """Fetch and display URL content."""
    response = httpx.get(url)
    print(response.text)

if __name__ == "__main__":
    app()
```

Make executable: `chmod +x script.py`

Run directly: `./script.py https://example.com`

## Critical Rules

1. **NEVER modify pyproject.toml or pixi.toml directly** - Always use `pixi add` or `uv add`
2. **NEVER install globally** - No `pip install`, `pip install --user`, or `sudo pip install`
3. **NO pip fallback** - If pixi/uv unavailable, ask user how to proceed
4. **Pixi features, not --dev** - Use `pixi add --feature dev`, NOT `pixi add --dev`
5. **Always detect project type** - Check for pixi.toml or pyproject.toml before installing
6. **Configure OpenCode for pixi** - Create opencode.json to run LSP servers in pixi environment

## Decision Tree

```
User wants to add dependency
│
├─ Is this a standalone script?
│  └─ YES → Use uv inline script metadata (PEP 723)
│
├─ Does pixi.toml exist?
│  └─ YES → Use pixi add [--feature NAME]
│
├─ Does [tool.pixi] exist in pyproject.toml?
│  └─ YES → Use pixi add [--feature NAME]
│
├─ Does pyproject.toml or uv.lock exist?
│  └─ YES → Use uv add [--dev]
│
└─ New project?
   └─ ASK: "Would you like pixi (system deps) or uv (pure Python)?"
```

## Common Workflows

### Starting a New Pixi Project

```bash
# Initialize with pyproject.toml (recommended)
pixi init --format pyproject

# Add Python and core deps
pixi add python=3.13

# Set up dev environment
pixi add --feature dev pytest black ruff mypy

# Configure VSCode
cat > .vscode/settings.json << 'EOF'
{
  "python.defaultInterpreterPath": "${workspaceFolder}/.pixi/envs/dev/bin/python",
  "ruff.path": ["${workspaceFolder}/.pixi/envs/dev/bin/ruff"]
}
EOF

# Install
pixi install
```

### Starting a New UV Project

```bash
# Initialize project
uv init myproject
cd myproject

# Add dependencies
uv add numpy polars

# Add dev dependencies
uv add --dev pytest black ruff mypy

# Sync environment
uv sync

# Run
uv run python -c "import numpy; print(numpy.__version__)"
```

### Converting Requirements.txt to Pixi

```bash
# Read requirements.txt and add each package
while read package; do
    pixi add "$package"
done < requirements.txt
```

### Converting Requirements.txt to UV

```bash
# Add each package
uv add $(cat requirements.txt)

# Or for dev requirements
uv add --dev $(cat requirements-dev.txt)
```

## Error Handling

### Tool Not Available

If pixi or uv is not installed:

```bash
# Check installation
which pixi  # or: which uv

# If missing, ask user:
echo "I need to install dependencies but [pixi/uv] is not available."
echo "How would you like me to proceed?"
echo "Options:"
echo "  1. Install pixi: curl -fsSL https://pixi.sh/install.sh | bash"
echo "  2. Install uv: curl -LsSf https://astral.sh/uv/install.sh | sh"
echo "  3. Use a different approach"
```

**DO NOT** automatically fall back to pip.

### Pixi Environment Not Found

```bash
# If .pixi/envs/dev doesn't exist
pixi install

# If specific environment missing
pixi install --environment dev
```

## Examples

### Example 1: Geospatial Project (Pixi)

```bash
# Pixi is recommended due to GDAL/GEOS system dependencies
pixi init --format pyproject
pixi add python=3.13 gdal geopandas rasterio shapely
pixi add --feature dev pytest black ruff pyright
pixi add --pypi polars  # PyPI-only package

# Configure OpenCode LSP
cat > opencode.json << 'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "lsp": {
    "pyright": {
      "command": ["pixi", "run", "--environment", "dev", "pyright-langserver", "--stdio"],
      "extensions": [".py", ".pyi"]
    },
    "ruff": {
      "command": ["pixi", "run", "--environment", "dev", "ruff", "server"],
      "extensions": [".py", ".pyi"]
    }
  }
}
EOF

pixi install
# OpenCode will now use LSP servers from pixi dev environment
```

### Example 2: Pure Python Web API (UV)

```bash
# UV is recommended for pure Python
uv init web-api
cd web-api
uv add fastapi uvicorn pydantic
uv add --dev pytest httpx black ruff

uv sync
uv run uvicorn main:app --reload
```

### Example 3: Quick Data Processing Script

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "polars>=1.0",
#     "pyarrow",
# ]
# ///

import polars as pl
import sys

# Read CSV, process, write output
df = pl.read_csv(sys.argv[1])
result = df.group_by("category").agg(pl.col("value").mean())
result.write_csv("output.csv")
print(f"Processed {len(df)} rows → {len(result)} categories")
```

```bash
chmod +x process.py
./process.py data.csv
```

## Checking Installed Packages

### Pixi

```bash
# List all packages in default environment
pixi list

# List packages in specific environment
pixi list --environment dev

# Show package info
pixi info
```

### UV

```bash
# List installed packages
uv pip list

# Show dependency tree
uv tree

# Show package details
uv pip show numpy
```

## When NOT to Use This Skill

- Installing system packages (use apt, brew, etc.)
- Managing non-Python dependencies
- Docker container setup (different workflow)
- Installing Python interpreters (use pyenv or uv python install)
- Global tool installation (use uvx or pixi global)
