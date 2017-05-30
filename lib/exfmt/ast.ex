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


  defp preprocess_node({:__block__, meta, args}) do
    new_args = pp_block(args)
    {:__block__, meta, new_args}
  end

  defp preprocess_node(tree) do
    tree
  end


  @defs ~w(def defp defmacro defmacrop defmodule)a

  defp pp_block(exprs) do
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
  defp space_group([], acc, _prev) do
    acc
  end

  defp space_group([expr | rest], acc, prev) do
    id = expr_id(expr)
    new_acc = case {id, prev} do
      {_, nil} ->
        [expr | acc]

      {:def, _} ->
        [expr, @newline | acc]

      _ ->
        [expr | acc]
    end
    space_group(rest, new_acc, id)
  end


  defp expr_id({type, _, _}) when type in @defs do
    :def
  end

  defp expr_id(_) do
    nil
  end


  defp group_id({type, _, [{name, _, _} | _]}) when type in @defs do
    {type, name}
  end

  defp group_id(_) do
    nil
  end
end
