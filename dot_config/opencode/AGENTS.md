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

# Code standards

CRITICAL: Never install or update dependencies. If any necessary dependencies are missing, describe it and prompt for user input. 
