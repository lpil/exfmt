defmodule Exfmt.Ast do
  @moduledoc """
  Functions for working with extended Elixir AST.

  """

  @newline {:"#newline", [], []}

  defdelegate to_algebra(ast, context), to: __MODULE__.ToAlgebra


  @doc """
  Preprocess an AST before printing.

  - Introduces empty lines where desired.

  """
  @spec preprocess(Macro.t) :: Macro.t
  def preprocess(ast) do
    Macro.postwalk(ast, &preprocess_node/1)
  end

  #
  # Private
  #

  defp preprocess_node({:__block__, meta, args}) do
    new_args = pp_block(args, [], nil)
    {:__block__, meta, new_args}
  end

  defp preprocess_node(tree) do
    tree
  end


  @defs ~w(def defp defmacro defmacrop defmodule)a

  defp pp_block([], acc, _) do
    Enum.reverse acc
  end

  defp pp_block([{_, _, _} = call | rest], acc, prev) do
    id = expr_id(call, prev)
    new_acc = case {id, prev} do
      # No padding for first expression in block
      {_, nil} ->
        [call | acc]

      # 1 line padding between clauses of the same definition
      {x, x} when elem(x, 0) == :def ->
        [call, @newline | acc]

      # No padding between attributes and next function
      {{:def, _, _}, :attr} ->
        [call | acc]

      # 2 line padding before new definitions
      {{:def, _, _}, _} ->
        [call, @newline, @newline | acc]

      # 2 line padding between attribute and previous definition
      {:attr, {:def, _, _}} ->
        [call, @newline, @newline | acc]

      # No padding for anything else
      _ ->
        [call | acc]
    end
    pp_block(rest, new_acc, id)
  end

  defp pp_block([expr | rest], acc, prev) do
    pp_block(rest, [expr | acc], prev)
  end


  #
  # We use expression IDs to determine whether an expressions
  # should be considered part of the same "group". We may insert
  # additional whitespace depending on whether adjacent expressions
  # are of the same group or not.
  #
  # For example, `defp foo(1)` and `defp foo(2)` both have the
  # expr_id `{:def, :def, :foo}`, and are considered part of the
  # same group.
  #
  defp expr_id({type, _, [{name, _, _} | _]}, _prev) when type in @defs do
    {:def, type, name}
  end

  defp expr_id({:@, _, _}, _prev) do
    :attr
  end

  defp expr_id(_, prev) do
    prev
  end
end
