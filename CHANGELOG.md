Changelog
=========

## v0.2.2 - 2017-06-13

- Semantic check algorithm now walks and compares two ASTs rather
  than relying on `Macro.to_string/1`. This change was advised by
  the Elixir team as `Macro.to_string/1` may not be entirely
  reliable.
- Rendering of anonymous functions in typespecs, and
  calls qualified by an atom from another call.
- Fix: Correctly insert spaces between function clauses when
  the function clause is preceeded by a comment.
- Fix: Correctly render capturing of qualified functions with arity
  specified.
- Fix: Render keyword lists with `[]` delimiters when a function
  argument in a position other than the final position.


## v0.2.1 - 2017-06-06

- Fix: Correctly render struct patterns with variable name.
  (https://github.com/lpil/exfmt/issues/7)
- Fix: Prevent crash with some uses of the Access protocol.
  (https://github.com/lpil/exfmt/issues/8)


## v0.2.0 - 2017-06-04

- The `mix exfmt` mix task has been added to enable people to try
  the formatter. This task reads source code from a file and prints
  the formatted output to STDOUT.
- Empty lines are inserted between certain expressions in a block
  in order to group them semantically.
- The semantics of formatted output is checked against the input
  source in order to ensure safety when rewriting code. This
  behaviour can be avoided by using `Exfmt.unsafe_format/2`.
- Improvements to how newlines are inserted with infix operators.
- Rendering of more expression:
  - Structs.
  - Map upserts.
  - Function capturing of infix operators.
  - __MODULE__ aliases.
  - Zero arity calls with do-end blocks.
  - Comments in case expressions.
  - Bitstrings.
  - String interpolation.
  - Multi-clause anonymous functions.
- FIX: Correctly escape characters that match delimiters when
  rendering sigils.
- FIX: Parse comments correctly when files contain sigils, or char
  literals.
- FIX: Avoid erroneous escaping when rendering sigils.
- FIX: Avoid crashing when a do block only contains `[]`.
- FIX: Avoid crashing when parsing a docstring sigil with content
  that looks like a string containing a hash.
- FIX: Prevent incorrect comment placement which results in
  semantically incorrect output.


## v0.1.0 - 2017-05-29

- First release! 🎉
- Elixir source code style can be checked with `Exfmt.check/2`.
- Elixir source code can be formatted with then `Exfmt.format/2`
  and `Exfmt.format!/2` functions.
