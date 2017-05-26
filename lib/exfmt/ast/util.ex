defmodule Exfmt.Ast.Util do
  @moduledoc false

  @doc """
  Given the arguments of a function call node, split the `do end`
  block arguments off, assuming any are present.

      iex> split_do_block([])
      {[], []}

      iex> split_do_block([1])
      {[1], []}

      iex> split_do_block([1, 2])
      {[1, 2], []}

      iex> split_do_block([1, 2, 3])
      {[1, 2, 3], []}

      iex> split_do_block([1, 2, [do: 3]])
      {[1, 2], [do: 3]}

      iex> split_do_block([1, 2, [do: 3], 4])
      {[1, 2, [do: 3], 4], []}

      iex> split_do_block([1, [do: 2, else: 3]])
      {[1], [do: 2, else: 3]}

      iex> split_do_block([[do: 1, else: 2]])
      {[], [do: 1, else: 2]}
  """
  def split_do_block([]) do
    {[], []}
  end

  def split_do_block([head | tail]) do
    do_split_do_block(tail, head, [])
  end

  defp do_split_do_block([], [{:do, _} | _] = prev, acc) do
    result = Enum.reverse(acc)
    {result, prev}
  end

  defp do_split_do_block([], prev, acc) do
    result = Enum.reverse([prev | acc])
    {result, []}
  end

  defp do_split_do_block([head | tail], prev, acc) do
    do_split_do_block(tail, head, [prev | acc])
  end
end
