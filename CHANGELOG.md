Changelog
=========

## Unreleased

- Support for Elixir v1.4 and lower has been dropped. This enables the use of
  new features added to the Elixir tokenizer and parser in v1.5.


## v0.3.0 - 2017-07-26

- Source code for formatting can be read from STDIN using the `--stdin`
  flag. Thanks @binaryseed!
- CLI now reports errors with STDERR and exit codes. Thanks @binaryseed!
  flag. Thanks @binaryseed!
- Editor integration for Atom. Thanks @rgreenjr!
- Editor integration for Vim. Thanks @jfornoff!
- Anon functions now always has a space between `fn` and `->`. Thanks
  @jfornoff!
- Rendering captured `&&/2`.

## v0.2.4 - 2017-07-20

- Rendering of more expressions:
  - Unsugared sigils.
  - Calls to `__block__/0`
  - Calls to `__aliases__/1`.
  - Aliases with a quoted base module.
  - Atoms starting with `Elixir.`.
  - Calls to function name atoms from another function.
  - Module attributes with values that have a block.
  - Struct patterns with pinned types.
  - Infix operators with module attribute assignment arguments.
  - Infix operators with captured fn arguments.
  - Infix operators with block arguments.
  - Structs with unquoted types.
  - Range structs.
- Fix: Parse comments from files containing `?\"`, `?\'`, or heredocs.
- Fix: Avoid applying `do` syntactic sugar to unsupported block words.
- Fix: Correctly escape sigils containing their close character.
- Fix: Correctly escape strings containing interpolation and newlines.


## v0.2.3 - 2017-07-04

- Rendering of more expressions:
  - Anon function calls with unquoted variable names.
  - Charlists with interpolation
  - `& &1` captured identity functions.
  - Captured Access protocol calls
  - Atom keys that require quotes.
  - Binaries of only string parts.
  - Maps with contents other than pairs.
  - Sigils with interpolation.
  - Defs with unquoted names.
  - Strings containing interpolation and quotes.
  - Infix operator arguments with blocks.
  - Maps updates where the original map came from a function all.
  - Aliases with variable parts.
Map updates wand captured map update functions.
- Fix: Correctly render multi-arity and multi-clause fns that have
  guard clauses.
- Fix: Surround call args with parems when any argument is a call
  with block arguments. This prevents the block being mistakenly
  assigned to the top level call instead of the child call.
- Fix: Avoid truncating large collections.
- Fix: Avoid corrupting utf8 characters in string interpolation
  and sigils.

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
