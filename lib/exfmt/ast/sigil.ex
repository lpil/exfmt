defmodule Exfmt.Ast.Sigil do
  @moduledoc """
  Helper functions for rendering sigils.

  """

  #
  # TODO: Rather than selecting from a primary option and a
  # secondary option, check every possible option until
  # suitable delimiters are found.
  #
  @doc """
  Determine what opening and closing character should be used
  to delimit a sigil.

  """
  @spec delimiters(char, [Macro.t]) :: {char, char}
  def delimiters(char, parts) do
    {primary_open, primary_close, alt_open, alt_close} = case char do
        c when c in [?r, ?R] ->
          {?/, ?/, ?(, ?)}

        _ ->
          {?(, ?), ?[, ?]}
      end
    close_str = IO.chardata_to_string([primary_close])
    if Enum.any?(parts, &contain_char?(&1, close_str)) do
      {alt_open, alt_close}
    else
      {primary_open, primary_close}
    end
  end


  defp contain_char?(part, char) when is_binary(part) do
    String.contains? part, char
  end


  defp contain_char?(_, _) do
    false
  end
end
