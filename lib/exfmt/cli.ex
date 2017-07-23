defmodule Exfmt.Cli do
  defmodule Output do
    defstruct [:stdout, :stderr, exit_code: 0]
  end

  @spec run(OptionParser.argv) :: %Output{}
  def run(argv) do
    argv
    |> parse_argv
    |> read_source
    |> format
    |> output
  end

  defp parse_argv(args) do
    {switches, args, _errors} = OptionParser.parse(args, [strict: [unsafe: :boolean, stdin: :boolean]])
    {Enum.into(switches, %{}), args}
  end

  defp read_source({%{stdin: true}=switches, args}) do
    source =
      case IO.read(:stdio, :all) do
        {:error, reason} -> {:error, reason}
        data -> {:ok, data}
      end
    {switches, args, source}
  end
  defp read_source({switches, [path]=args}) do
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

  defp output({:ok, formatted}) do
    %Output{
      exit_code: 0,
      stdout: formatted,
    }
  end
  defp output(%{__exception__: true}=exception) do
    %Output{
      exit_code: 1,
      stderr: Exception.message(exception),
    }
  end
  defp output({switches, args, {:error, reason}}) do
    %Output{
      exit_code: 1,
      stderr: """
        Error: #{:file.format_error(reason)}
        Args: #{inspect switches} #{inspect args}
      """,
    }
  end
end
