defmodule Mix.Tasks.Exfmt do
  @moduledoc """
  Formats Elixir source code.

      mix exfmt path/to/file.ex

  ## Command line options

    * `--stdin` - Read from STDIN instead of a file
    * `--unsafe` - Disable the semantics check that verifies
      that `exmft` has not altered the semantic meaning of
      the input file.

  """

  @shortdoc  "Format Elixir source code"
  @usage """
  USAGE:
      mix exfmt path/to/file.ex
  """

  use Mix.Task

  alias Exfmt.Cli

  @doc false
  @spec run(OptionParser.argv) :: any
  def run([]) do
    Mix.Shell.IO.error(@usage)
  end
  def run(argv) do
    argv
    |> Cli.run()
    |> execute
  end

  def execute(%Cli.Output{exit_code: 1, stderr: stderr}) do
    Mix.Shell.IO.error(stderr)
    System.halt(1)
  end
  def execute(%Cli.Output{exit_code: 0, stdout: stdout}) do
    IO.write(stdout)
  end
end
