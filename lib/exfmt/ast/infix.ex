defmodule Exfmt.Ast.Infix do
  @moduledoc """
  Handling the conversion of infix operators to Algebgra.

  We need to be especially careful when rendering infix
  operators because we may need to render them differently
  depending on what the parent call is.

  For example, if we had the AST `{:*, [], [{:+, [] [1, 2}, 3]}`
  we might nievely render it like so:

      1 + 2 * 3

  However `:*` binds more tightly than `:+`, so it should
  actually be rendered with parens like so:

      (1 + 2) * 3

  Failure to do render with parens results in the `:*` and `:+`
  operators to swap positions in the AST.

  """

  alias Exfmt.Context
  alias Exfmt.Ast.Util

  @infix_ops ~W[=== !== == != <= >= && || <> ++ -- \\ :: <- .. |> =~ < > -> +
                - * / = | . and or when in ~>> <<~ ~> <~ <~> <|> <<< >>> |||
                &&& ^^^ ~~~]a

  @doc """
  A compile time list of all the infix operator atoms.

  """
  @spec infix_ops :: [atom]
  defmacro infix_ops do
    @infix_ops
  end


  @doc """
  Determine whether an infix operator's argument is to be wrapped
  in parens in order to render correctly.

  """
  @spec wrap?(Macro.t, :left | :right, Context.t) :: boolean
  def wrap?({op, _, _}, side, ctx) when op in @infix_ops do
    with [parent | _] <- ctx.stack,
         {parent_assoc, parent_prec} <- binary_op_props(parent),
         {_, prec} <- binary_op_props(op) do
      presedence_wrap? side, prec, parent_prec, parent_assoc
    else
      _ ->
        false
    end
  end

  def wrap?({:__block__, _, _}, _, _) do
    true
  end

  def wrap?({:@, _, [{_, _, value}]}, _, _) when value != nil do
    true
  end

  def wrap?({:&, _, [arg]}, _, _) when not is_integer(arg) do
    true
  end

  def wrap?(ast, _, _) do
    Util.call_with_block? ast
  end


  defp presedence_wrap?(side, prec, parent_prec, parent_assoc) do
    if parent_prec == prec do
      parent_assoc != side
    else
      parent_prec > prec
    end
  end


  #
  # This function has been adapted from
  # `elixir-lang/elixir/lib/elixir/lib/macro.ex`
  #
  @spec binary_op_props(atom) :: {:left | :right, precedence :: integer} | :not_op
  defp binary_op_props(o) do
    case o do
      o when o in [:<-, :\\] ->
        {:left, 40}

      :when ->
        {:right, 50}

      ::: ->
        {:right, 60}

      :| ->
        {:right, 70}

      := ->
        {:right, 90}

      o when o in [:||, :|||, :or] ->
        {:left, 130}

      o when o in [:&&, :&&&, :and] ->
        {:left, 140}

      o when o in [:==, :!=, :=~, :===, :!==] ->
        {:left, 150}

      o when o in [:<, :<=, :>=, :>] ->
        {:left, 160}

      o when o in [:|>, :<<<, :>>>, :<~, :~>, :<<~, :~>>, :<~>, :<|>, :^^^] ->
        {:left, 170}

      :in ->
        {:left, 180}

      o when o in [:++, :--, :.., :<>] ->
        {:right, 200}

      o when o in [:+, :-] ->
        {:left, 210}

      o when o in [:*, :/] ->
        {:left, 220}

      :. ->
        {:left, 310}

      _ ->
        :not_op
    end
  end
end
