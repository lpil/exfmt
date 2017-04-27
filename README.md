# Exfmt

## Plan

- [ ] Semantic correctness. Exfmt can rewrite any Elixir code
  without changing the semantic meaning of the code. Running
  Exfmt will not cause breakages.
- [ ] Presevation of comments. Exfmt will not strip comments
  from Elixir code.
  - [ ] Comment parsing.
  - [ ] Merging of Elixir AST and comments.
  - [ ] Printing of AST with comments.
- [ ] Adhere to the Elixir style guide.
  - [ ] Capable of forcing a collection of breaks to all either
    be a space or a newline together. For function args, lists, etc.
  - [ ] Capable of nesting by a variable amount depending on
    lengths that depend upon rendering. e.g. function arguments.
- [ ] CLI.
