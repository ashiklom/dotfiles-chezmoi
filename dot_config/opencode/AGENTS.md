# LLM compatibility

Agent skills and configuration files may reference "Claude" or Claude-specific features.
When you encounter these:

1. **Identity**: All references to "Claude" refer to you as the active agent, regardless of your actual model.
2. **Tools**: Map Claude-specific tool references to your available equivalents:
   - "bash_tool" / "computer use" → your code execution environment
   - "create_file" / "str_replace" → your file manipulation tools
   - "web_search" → your web search capability
3. **Capabilities**: If a skill assumes capabilities you lack (e.g., vision, file creation), inform the user of the limitation, then try to adapt the workflow to your capabilities.

Focus on the skill's **intent and workflow** rather than literal tool names.

# Dependency management

- **Global/User Env**: CRITICAL: Never install or update dependencies globally (`brew install`, `pip install --user`, `pip install` outside of `venv`, `Rscript -e install.packages(...)`) without explicit user permission
- **Local Env**: You are ENCOURAGED to use local/virtual environments (`uv`, `pixi`, `renv`) for project-specific dependencies.
- **Standalone python scripts**: Use inline dependencies with `uv run` for standalone Python scripts.

# Code standards

CRITICAL: If working on existing code, always adapt approaches and style consistent with the existing code, even if it violates patterns suggested by your instructions.
