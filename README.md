# exfmt

## Plan

- [ ] Semantic correctness. Exfmt can rewrite any Elixir code
  without changing the semantic meaning of the code. Running
  Exfmt will not cause breakages.
- [x] Preservation of comments. Exfmt will not strip comments
  from Elixir code.
  - [x] Comment parsing.
  - [x] Merging of Elixir AST and comments.
  - [x] Printing of AST with comments.
- [ ] Adhere to the Elixir style guide.
  - [x] Capable of forcing a collection of breaks to all either
    be a space or a newline together. For function args, lists, etc.
  - [ ] Capable of nesting by a variable amount depending on
    lengths that depend upon rendering. e.g. function arguments.
- [ ] CLI.
