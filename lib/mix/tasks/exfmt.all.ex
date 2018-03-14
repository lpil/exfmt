defmodule Mix.Tasks.Exfmt.All do
  @moduledoc """
  Formats Elixir source code in specified directory recursively.
  mix exfmt.all path/to/dir/
  ## Command line options
  * `--overwrite` Overwrite files that formatted by exfmt.
  """

  @shortdoc  "Format Elixir source code in specified directory."
  @usage """
  USAGE:
      mix exfmt.all path/to/dir/
  """
  use Mix.Task
  alias Exfmt.{SyntaxError, SemanticsError}

  @doc false
  @spec run(OptionParser.argv) :: any
  def run([]) do
    @usage
    |> red()
    |> IO.write()
  end

  def run(args) do
    option_parser_options = [strict: [overwrite: :boolean]]
    {opts, [path], []} = OptionParser.parse(args, option_parser_options)
    #TODO: Add code that checks path is a directory path.
    files = Path.join(path, "**/*.ex")
            |> Path.wildcard()
    Enum.each(files, &format_dir(&1, opts))
  end

  defp format_dir(path, opts) do
    {:ok, source} = File.read(path)
    case Exfmt.format(source, 100) do
      {:ok, formatted} ->
        if source == formatted do
          IO.write("#{path} is already formatted collectly")
        else
          "#{path} does not formatted collectly!"
          |> red()
          |> IO.puts()
          if opts[:overwrite] do
            File.write!(path, formatted, [])
            IO.write("#{path} is now formatted.")
          end
        end
      %SemanticsError{message: message} ->
        message
        |> red()
        |> IO.puts()
      %SyntaxError{message: message} ->
        message
        |> red()
        |> IO.puts()
    end
  end
  defp red(msg) do
    [IO.ANSI.red, msg, IO.ANSI.reset]
  end
end
