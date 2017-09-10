[![Circle CI](https://circleci.com/gh/lpil/exfmt.svg?style=shield)](https://circleci.com/gh/lpil/exfmt)
[![Hex version](https://img.shields.io/hexpm/v/exfmt.svg "Hex version")](https://hex.pm/packages/exfmt)
[![API Docs](https://img.shields.io/badge/api-docs-green.svg?style=flat)](https://hexdocs.pm/exfmt/)
[![Licence](https://img.shields.io/github/license/lpil/exfmt.svg)](https://www.apache.org/licenses/LICENSE-2.0)

# exfmt 🌸

> `exfmt` is in alpha.  If you run into any problems, please
> [report them][issues].
>
> **The format produced by exfmt will change significantly before the 1.0.0
> release.**  If this will cause problems for you, please refrain from using
> exfmt during the alpha- and beta-test periods.

[issues]: https://github.com/lpil/exfmt/issues

`exfmt` is inspired by Aaron VonderHaar's [elm-format][elm-format], and aims
to format [Elixir][elixir] source code largely according to the standards
defined in Aleksei Magusev's [Elixir Style Guide][style-guide].


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

[elixir]: https://elixir-lang.org/
[elm-format]: https://github.com/avh4/elm-format
[style-guide]: https://github.com/lexmag/elixir-style-guide


## Contents
- [Installation](#installation)
- [Usage](#usage)
- [Installation](#editor-integration)
- [Editor Integration](#editor-integration)
  - [Atom](#atom)
  - [Vim](#vim)
  - [VS Code](#visual-studio-code)
- [Development](#development)

## Installation

If you run Elixir 1.4+, you can use `mix archive.install hex exfmt`, otherwise add it to your project as a dependancy.

## Usage

```sh
mix exfmt path/to/file.ex
```

### Command line options

* `--check` - Check if file is formatted, sets exit status
  to 1 if false.
* `--stdin` - Read from STDIN instead of a file.
* `--unsafe` - Disable the semantics check that verifies
  that `exmft` has not altered the semantic meaning of
  the input file.


## Installation

`exfmt` makes use of Elixir compiler features coming in Elixir v1.6.0 and as a
result can only be run with Elixir v1.6-dev off the Elixir master branch,
which you will need to download and compile yourself. Use with earlier
versions may work without crashing, but the output format will be incorrect.

An easier method of installation will be availible when Elixir v1.6.0 is
released. Or sooner, perhaps!


## Editor integration

### Atom

Atom users can install Ron Green's [exfmt-atom][exfmt-atom] package.

[exfmt-atom]: https://atom.io/packages/exfmt-atom


### Vim

Vim users can use exfmt with Steve Dignam's [Neoformat][neoformat].

[neoformat]: https://github.com/sbdchd/neoformat

Once installed the following config will enable formatting of the current
Elixir buffer using `:Neoformat`. For further instructions, please reference
the Neoformat documentation.

```viml
let g:neoformat_elixir_exfmt = {
  \ 'exe': 'mix',
  \ 'args': ['exfmt', '--stdin'],
  \ 'stdin': 1
  \ }

let g:neoformat_enabled_elixir = ['exfmt']
```


### Visual Studio Code

VSCode users can use exfmt with James Hrisho's [vscode-exfmt][vscode-exfmt] package.

[vscode-exfmt]: https://github.com/securingsincity/vscode-exfmt
