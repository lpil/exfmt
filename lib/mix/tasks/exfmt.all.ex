defmodule Mix.Tasks.ExFmt.All do
  use Mix.Task
  alias Exfmt.{SyntaxError, SemanticsError}
  def run([]) do
    files = Path.join("./lib/", "**/*.ex")
            |> Path.wildcard()
    Enum.each(files, &format_file(&1))
  end

  defp format_file(path) do
    with {:file, _, {:ok, source}} <- {:file, path, File.read(path)},
         {:ok, formatted} <- Exfmt.format(source, 100) do
      IO.write(formatted)
    else
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
