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

  @doc false
  @spec run(OptionParser.argv) :: any
  def run([]) do
    @usage
    |> Mix.Shell.IO.error
  end

  def run(args) do
    args
    |> parse
    |> input
    |> format
    |> output
  end

  def parse(args) do
    {switches, args, _errors} = OptionParser.parse(args, [strict: [unsafe: :boolean, stdin: :boolean]])
    {Enum.into(switches, %{}), args}
  end

  defp input({%{stdin: true}=switches, args}) do
    source =
      case IO.read(:stdio, :all) do
        {:error, reason} -> {:error, reason}
        data -> {:ok, data}
      end
    {switches, args, source}
  end
  defp input({switches, [path]=args}) do
    {switches, args, File.read(path)}
  end

  defp format({%{unsafe: true}, _args, {:ok, source}}) do
    Exfmt.unsafe_format(source)
  end
  defp format({_switches, _args, {:ok, source}}) do
    Exfmt.format(source)
  end
  defp format({switches, args, {:error, _reason}=error}) do
    {switches, args, error}
  end

  def output({:ok, formatted}) do
    IO.write(formatted)
  end
  def output(%{}=exception) do
    Mix.Shell.IO.error(Exception.message(exception))
  end
  def output({switches, args, {:error, reason}}) do
    Mix.Shell.IO.error("Error: #{:file.format_error(reason)}")
    Mix.Shell.IO.error("Switches: #{inspect switches}")
    Mix.Shell.IO.error("Args: #{inspect args}")
  end
end
