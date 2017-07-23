defmodule Exfmt.Cli do
  @moduledoc """
  Providing the logic behind command line interfaces for Exfmt.
  Currently the mix task, later also an escript?

  """

  defmodule Output do
    @moduledoc """
    Struct containing the to-be-performed IO the CLI module produces.

    """
    defstruct [:stdout, :stderr, {:exit_code, 0}]
  end


  @spec run(OptionParser.argv) :: %Output{}
  def run(argv) do
    argv
    |> parse_argv()
    |> read_source()
    |> format_source()
    |> construct_output()
  end


  defp parse_argv(args) do
    {switches, args, _errors} =
      OptionParser.parse(args, strict: [unsafe: :boolean, stdin: :boolean])
    {Enum.into(switches, %{}), args}
  end


  defp read_source({%{stdin: true} = switches, args}) do
    source =
      case IO.read(:stdio, :all) do
        {:error, reason} ->
          {:error, reason}

        data ->
          {:ok, data}
      end
    {switches, args, source}
  end

  defp read_source({switches, [path] = args}) do
    {switches, args, File.read(path)}
  end


  defp format_source({%{unsafe: true}, _args, {:ok, source}}) do
    Exfmt.unsafe_format source
  end

  defp format_source({_switches, _args, {:ok, source}}) do
    Exfmt.format source
  end

  defp format_source({switches, args, {:error, _reason} = error}) do
    {switches, args, error}
  end


  defp construct_output({:ok, formatted}) do
    %Output{exit_code: 0, stdout: formatted}
  end

  defp construct_output(%{__exception__: true} = exception) do
    %Output{exit_code: 1, stderr: Exception.message(exception)}
  end

  defp construct_output({_switches, args, {:error, reason}}) do
    stderr = """
    Error: #{:file.format_error(reason)}

        #{hd(args)}
    """
    %Output{exit_code: 1, stderr: stderr}
  end
end
