defmodule Exfmt.AST.Util do
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
