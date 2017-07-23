[![Circle CI](https://circleci.com/gh/lpil/exfmt.svg?style=shield)](https://circleci.com/gh/lpil/exfmt)
[![Hex version](https://img.shields.io/hexpm/v/exfmt.svg "Hex version")](https://hex.pm/packages/exfmt)
[![API Docs](https://img.shields.io/badge/api-docs-green.svg?style=flat)](https://hexdocs.pm/exfmt/)
[![Licence](https://img.shields.io/github/license/lpil/exfmt.svg)](https://www.apache.org/licenses/LICENSE-2.0)
<!-- [![Hex downloads](https://img.shields.io/hexpm/dt/exfmt.svg "Hex downloads")](https://hex.pm/packages/exfmt) -->

# exfmt 🌸

> `exfmt` is in alpha.  If you run into any problems, please
> [report them][issues].
>
> Currently exfmt does not always produce semantically identical formatted
> Elixir. There are checks to prevent data loss, but please ensure you have
> backed up your code before running `exfmt` during this alpha stage.
>
> **The format produced by exfmt will change significantly before the 1.0.0
> release.**  If this will cause problems for you, please refrain from using
> exfmt during the alpha- and beta-test periods.

`exfmt` formats [Elixir][elixir] source code according to the standards defined in the [Elixir Style Guide][style-guide]. It is inspired by Aaron VonderHaar's [elm-format][elm-format].

```elixir
# exfmt takes any Elixir code...

defmodule MyApp, do: (
    use( SomeLib )
    def run( data ), do: {
      :ok,
      data
   }
)

# and rewrites it in a clean and idiomatic style:

defmodule MyApp do
  use SomeLib

  def run(data) do
    {:ok, data}
  end
end
```

The benefits of `exfmt`:

 - It makes code **easier to write**, because you never have to worry about
   minor formatting concerns while powering out new code.
 - It makes code **easier to read**, because there are no longer distracting
   minor stylistic differences between different code bases. As such, your
   brain can map more efficiently from source to mental model.
 - It makes code **easier to maintain**, because you can no longer have diffs
   related only to formatting; every diff necessarily involves a material
   change.
 - It **saves your team time** debating how to format things, because there is
   a standard tool that formats everything the same way.
 - It **saves you time** because you don't have to nitpick over formatting
   details of your code.

[issues]: https://github.com/lpil/exfmt/issues
[prs]: https://github.com/lpil/exfmt/pulls
[elixir]: https://elixir-lang.org/
[elm-format]: https://github.com/avh4/elm-format
[style-guide]: https://github.com/lexmag/elixir-style-guide


## Contents

- [Usage](#usage)
- [Development](#development)


## Usage

```sh
# Preview the exfmt formatting of an Elixir source file
mix exfmt path/to/file.ex
```


## Development

`exfmt` is an open project, contributions are very much welcomed. If you have
feedback or have found a bug, please open [an issue][issues]. If you wish to
make a code contribution please open a [pull request][prs], though for larger
code changes it may be good to open an issue first so we can work out the best
way to move forward.

Please note that this project is released with a [Contributor Code of
Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to
abide by its terms.

```sh
# Install the deps
mix deps.get

# Run the tests
mix test

# Run the tests when files change
mix test.watch

# Run the type checker
mix dialyzer
```
