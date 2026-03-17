# Copilot Project Directives

## Code Style
- All code comments must be written in English, even if the chat (prompt) is in French.
- All files created must follow the existing code style of the project and must be written in English (files: gd md sh tscn), even if the chat (prompt) is in French.
- For assignments with multiple lines, align the `=` or `:` signs vertically (tabular alignment, like a linter).
- Only use classic comments `# ...` for functions and code (no docstring `""" ... """`).
- no type hints in function definitions (e.g., `func my_function(arg1, arg2):` instead of `func my_function(arg1: int, arg2: String) -> void:`).

## Godot Architecture - Programmatic Scene Building
- **Minimize .tscn files**: Keep all scene files (.tscn) to bare minimum - only root node + script reference
- **Programmatic UI/Hierarchy**: Build all scene hierarchies, UI elements, and configurations in .gd scripts using `_setup_scene()` methods
- **Pattern**: Each scene class should have:
  1. `_setup_scene()` - creates all child nodes and applies all styling/configuration
  2. Called from `_ready()` with safety check: `if not main_node: _setup_scene()`
  3. All node references stored as class variables

## Chat Response Style
- Always reply in French in the chat (prompt).
- Keep answers short, concise, and avoid unnecessary explanations.

## Example
```python
# Example of aligned assignments
player_x    = 10
player_y    = 20
player_life = 3

# English comments
```

---
**Apply these rules for all code and chat interactions in this project.**