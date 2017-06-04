defmodule Mix.Tasks.Exfmt do
  @moduledoc """
  Formats Elixir source code.

      mix exfmt path/to/file.ex

  ## Command line options

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
  alias Exfmt.{SyntaxError, SemanticsError}

  @doc false
  def run([]) do
    @usage
    |> red()
    |> IO.write()
  end

  def run(args) do
    with {opts, [path], []} <- OptionParser.parse(args, unsafe: :boolean),
         {:file, _, {:ok, source}} <- {:file, path, File.read(path)},
         {:ok, formatted} <- format(source, opts) do
      IO.write formatted
    else
      {:file, path, {:error, :enoent}} ->
        "Error: No such file or directory:\n    #{path}"
        |> red()
        |> IO.puts

      {:file, path, {:error, :eisdir}} ->
        "Error: Input is a directory, not an Elixir source file:\n   #{path}"
        |> red()
        |> IO.puts


      {:file, path, {:error, :eacces}} ->
        "Error: Incorrect permissions, unable to read file:\n   #{path}"
        |> red()
        |> IO.puts

      {:file, path, {:error, :enomem}} ->
        "Error: Not enough memory to read file:\n   #{path}"
        |> red()
        |> IO.puts

      {:file, path, {:error, :enotdir}} ->
        "Error: Unable to open a parent directory:\n   #{path}"
        |> red()
        |> IO.puts

      %SemanticsError{message: message} ->
        message
        |> red()
        |> IO.puts

      %SyntaxError{message: message} ->
        message
        |> red()
        |> IO.puts
    end
  end


  defp format(source, opts) do
    if opts[:unsafe] do
      Exfmt.unsafe_format(source)
    else
      Exfmt.format(source, 100)
    end
  end


  defp red(msg) do
    [IO.ANSI.red, msg, IO.ANSI.reset]
  end
end
