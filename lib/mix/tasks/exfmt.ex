defmodule Mix.Tasks.Exfmt do
  @moduledoc """
  Formats Elixir source code.

      mix exfmt path/to/file.ex

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
    IO.write [IO.ANSI.red, @usage, IO.ANSI.reset]
  end

  def run([path]) do
    with {:ok, source} <- File.read(path),
         {:ok, formatted} <- Exfmt.format(source) do
      IO.write formatted
    else
      {:error, :enoent} ->
        "Error: No such file or directory:\n    #{path}"
        |> red()
        |> IO.puts

      {:error, :eisdir} ->
        "Error: Input is a directory, not an Elixir source file:\n   #{path}"
        |> red()
        |> IO.puts


      {:error, :eacces} ->
        "Error: Incorrect permissions, unable to read file:\n   #{path}"
        |> red()
        |> IO.puts

      {:error, :enomem} ->
        "Error: Not enough memory to read file:\n   #{path}"
        |> red()
        |> IO.puts

      {:error, :enotdir} ->
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

  defp red(msg) do
    [IO.ANSI.red, msg, IO.ANSI.reset]
  end
end
