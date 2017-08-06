defmodule Exfmt.Ast do
  @moduledoc """
  Functions for working with extended Elixir AST.

  """

  @newline {:"#newline", [], []}
  @defs ~w(def defp defmacro defmacrop defmodule)a
  @imports ~w(use import require alias doctest)a


  defdelegate to_algebra(ast, context), to: __MODULE__.ToAlgebra

  @doc """
  Compare two ASTs to see if they are semantically equivalent.

  """
  @spec eq?(Macro.t, Macro.t) :: boolean
  def eq?({:__block__, _, [x]}, {name, _, _} = y) when name != :__block__ do
    eq?(x, y)
  end

  def eq?({name, _, _} = x, {:__block__, _, [y]}) when name != :__block__ do
    eq?(x, y)
  end

  def eq?({x_name, _, x_args}, {y_name, _, y_args}) do
    eq?(x_name, y_name) and eq?(x_args, y_args)
  end

  def eq?([x | xs], [y | ys]) do
    eq?(x, y) and eq?(xs, ys)
  end

  def eq?({x1, x2}, {y1, y2}) do
    eq?(x1, y1) and eq?(x2, y2)
  end

  def eq?(x, y) do
    x == y
  end


  @doc """
  Introduces empty lines to group related expressions.

  """
  @spec insert_empty_lines(Macro.t) :: Macro.t
  def insert_empty_lines(ast) do
    Macro.postwalk(ast, &node_insert_empty_lines/1)
  end


  defp node_insert_empty_lines({:__block__, meta, args}) do
    new_args = block_insert_empty_lines(args)
    {:__block__, meta, new_args}
  end

  defp node_insert_empty_lines(tree) do
    tree
  end


  defp block_insert_empty_lines(exprs) do
    exprs
    |> group_by_def()
    |> Enum.map(&space_group(&1, [], nil))
    |> Enum.intersperse([@newline, @newline])
    |> Enum.reverse()
    |> Enum.concat()
  end


  #
  # Group expressions by definitions.
  # When a new function/macro is defined a new group starts,
  # pulling in any expressions which had not yet been assigned
  # to a group.
  #
  @doc false
  def group_by_def(exprs, groups \\ [], tbd \\ [], prev \\ nil)

  def group_by_def([], groups, tbd, _prev) do
    put_in_latest_group(groups, tbd)
  end

  # New expr which may be the first definition (as prev is nil)
  #
  def group_by_def([expr | rest], groups, tbd, nil) do
    case group_id(expr) do
      nil ->
        new_tbd = [expr | tbd]
        group_by_def(rest, groups, new_tbd, nil)

      id ->
        new_groups = put_in_latest_group(groups, [expr | tbd])
        group_by_def(rest, new_groups, [], id)
    end
  end

  # New call which may be a new definition
  #
  def group_by_def([expr | rest], groups, tbd, prev) do
    case group_id(expr) do
      nil ->
        new_tbd = [expr | tbd]
        group_by_def(rest, groups, new_tbd, prev)

      ^prev ->
        new_groups = put_in_latest_group(groups, [expr | tbd])
        group_by_def(rest, new_groups, [], prev)

      id ->
        group = [expr | tbd]
        new_groups = [group | groups]
        group_by_def(rest, new_groups, [], id)
    end
  end


  defp put_in_latest_group([], exprs) do
    [exprs]
  end

  defp put_in_latest_group([latest | groups], exprs) do
    [exprs ++ latest | groups]
  end


  #
  # Insert empty lines within a group. For example, between
  # function clauses.
  #
  # Groups are reversed, so the last expression in a block is the
  # first in the group.
  #
  defp space_group([], acc, _prev) do
    acc
  end

  defp space_group([expr | rest], acc, prev) do
    id = expr_id(expr)
    new_acc = case {id, prev} do
      {_, nil} ->
        [expr | acc]

      {:import, :import} ->
        [expr | acc]

      {:defdelegate, :defdelegate} ->
        [expr | acc]

      {:defdelegate, _} ->
        [expr, @newline | acc]

      {:import, _} ->
        [expr, @newline | acc]

      {:moduledoc, _} ->
        [expr, @newline | acc]

      {_, :doc} ->
        [expr, @newline | acc]

      {:def, _} ->
        [expr, @newline | acc]

      {_, :defdelegate} ->
        [expr, @newline | acc]

      _ ->
        [expr | acc]
    end
    space_group(rest, new_acc, id)
  end


  defp expr_id({type, _, _}) when type in @defs do
    :def
  end

  defp expr_id({type, _, _}) when type in @imports do
    :import
  end

  defp expr_id({:defdelegate, _, _}) do
    :defdelegate
  end

  defp expr_id({:@, _, [{:doc, _, _}]}) do
    :doc
  end

  defp expr_id({:@, _, [{:moduledoc, _, _}]}) do
    :moduledoc
  end

  defp expr_id(_) do
    :other
  end


  defp group_id({type, _, [{name, _, _} | _]}) when type in @defs do
    {type, name}
  end

  defp group_id(_) do
    nil
  end


  @doc """
  Compact block wrapped literals into specialised forms.

  """
  @spec compact_wrapped_literals(Macro.t) :: Macro.t
  def compact_wrapped_literals(ast)  do
    Macro.postwalk(ast, &node_compact_wrapped_literals/1)
  end

  defp node_compact_wrapped_literals({:__block__, _meta, [ast]}) do
    ast
  end

  defp node_compact_wrapped_literals(ast) do
    ast
  end
end
