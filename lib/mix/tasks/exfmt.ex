defmodule Mix.Tasks.Exfmt do
  @moduledoc """
  ## Usage

      mix exfmt path/to/file.ex

  ## Command line options

    * `--check` - Check if file is formatted, sets exit status
      to 1 if false.
    * `--stdin` - Read from STDIN instead of a file.
    * `--unsafe` - Disable the semantics check that verifies
      that `exmft` has not altered the semantic meaning of
      the input file.
  """

  @shortdoc "Format Elixir source code"
  use Mix.Task
  alias Exfmt.Cli

  @doc false
  @spec run(OptionParser.argv) :: any
  def run([]) do
    Mix.Shell.IO.error @moduledoc
  end

  def run(argv) do
    argv
    |> Cli.run()
    |> execute_output()
  end


  defp execute_output(output) do
    if output.stdout do
      output.stdout
      |> String.trim()
      |> Mix.shell().info
    end
    if output.stderr do
      output.stderr
      |> String.trim()
      |> Mix.shell().error
    end
    if output.exit_code && output.exit_code != 0 do
      System.halt output.exit_code
    end
  end
end
