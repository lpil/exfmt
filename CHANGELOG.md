Changelog
=========

## Unreleased

- The `mix exfmt` mix task has been added to enable people to try
  the formatter. This task reads source code from a file and prints
  the formatted output to STDOUT.
- Empty lines are inserted between certain expressions in a block
  in order to group them semantically.
- The semantics of formatted output is checked against the input
  source in order to ensure safety when rewriting code. This
  behaviour can be avoided by using `Exfmt.unsafe_format/2`.
- Rendering of structs, map upsert syntax, more function capture
  syntaxes, and string interpolation.
- FIX: Correctly escape charactes that match delimeters when
  rendering sigils.
- FIX: Parse comments correctly when files contain sigils, or char
  literals.

## v0.1.0 - 2017-05-29

- First release! 🎉
- Elixir source code style can be checked with `Exfmt.check/2`.
- Elixir source code can be formatted with then `Exfmt.format/2`
  and `Exfmt.format!/2` functions.
