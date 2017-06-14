defmodule Mix.Tasks.Exfmt.All do
  use Mix.Task
  alias Exfmt.{SyntaxError, SemanticsError}
  def run(args) do
    option_parser_options = [strict: [unsafe: :boolean]]
    {_opts, [path], []} = OptionParser.parse(args, option_parser_options)
    files = Path.join(path, "**/*.ex")
            |> Path.wildcard()
    Enum.each(files, &format_dir(&1))
  end

  defp format_dir(path) do
    {:ok, source} = File.read(path)
    case Exfmt.format(source, 100) do
      {:ok, formatted} ->
        if source == formatted do
          IO.write("#{path} is already formatted collectly")
        else
          "#{path} does not formatted collectly!"
          |> red()
          |> IO.puts()
          File.write!(path, formatted, [])
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
