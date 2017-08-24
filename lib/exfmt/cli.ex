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
    with {switches, args} <- parse_argv(argv),
         {:ok, source} <- read_source(switches, args),
         {:ok, result} <- process(source, switches) do
      %Output{exit_code: 0, stdout: result}
    else
      :ok ->
        %Output{exit_code: 0}

      :no_input_error ->
        %Output{exit_code: 1, stderr: "No input files given"}

      {:format_error, _} ->
        %Output{exit_code: 1}

      {:error, reason} ->
        %Output{exit_code: 1, stderr: "Error: #{:file.format_error(reason)}"}

      %{__exception__: true} = exception ->
        %Output{exit_code: 1, stderr: Exception.message(exception)}
    end
  end


  defp parse_argv(args) do
    opts = [check: :boolean, unsafe: :boolean, stdin: :boolean]
    {switches, args, _errors} = OptionParser.parse(args, strict: opts)
    {Enum.into(switches, %{}), args}
  end


  defp read_source(%{stdin: true}, _args) do
    case IO.read(:stdio, :all) do
      {:error, reason} ->
        {:error, reason}

      data ->
        {:ok, data}
    end
  end

  defp read_source(_, [path]) do
    File.read path
  end

  defp read_source(_, _) do
    :no_input_error
  end


  defp process(source, %{check: true}) do
    Exfmt.check source
  end

  defp process(source, %{unsafe: true}) do
    Exfmt.unsafe_format source
  end

  defp process(source, _switches) do
    Exfmt.format source
  end
end
