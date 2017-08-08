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

      iex> split_do_block([1, [do: 2, rescue: 3]])
      {[1], [do: 2, rescue: 3]}

      iex> split_do_block([[do: 1, else: 2]])
      {[], [do: 1, else: 2]}

      iex> split_do_block([1, [else: 2, do: 3]])
      {[1, [else: 2, do: 3]], []}

      iex> split_do_block([1, [do: 2, rescue: 3, else: 4]])
      {[1], [do: 2, rescue: 3, else: 4]}

  """
  def split_do_block([]) do
    {[], []}
  end

  def split_do_block([head | tail]) do
    do_split_do_block tail, head, []
  end


  defp do_split_do_block([], [{:do, _} | _] = prev, acc) do
    if Enum.all?(prev, &keyword_block?/1) do
      result = Enum.reverse(acc)
      {result, prev}
    else
      result = Enum.reverse([prev | acc])
      {result, []}
    end
  end

  defp do_split_do_block([head | tail], prev, acc) do
    do_split_do_block tail, head, [prev | acc]
  end

  defp do_split_do_block([], prev, acc) do
    result = Enum.reverse([prev | acc])
    {result, []}
  end


  defp keyword_block?({word, _}) do
    word in [:do, :after, :else, :rescue, :catch]
  end

  defp keyword_block?(false) do
    false
  end


  @doc """
  Given an AST node, determine if the node is a call with block arguments.

      iex> call_with_block?(1)
      false

      iex> call_with_block?("Hello")
      false

      iex> call_with_block?(quote do run(:ok) end)
      false

      iex> call_with_block?(quote do run :ok do nil end end)
      true

  """
  @spec call_with_block?(Macro.t) :: boolean
  def call_with_block?({_, _, args}) when is_list(args) do
    case List.last(args) do
      [{:do, _} | _] ->
        true

      _ ->
        false
    end
  end


  def call_with_block?(_) do
    false
  end
end
