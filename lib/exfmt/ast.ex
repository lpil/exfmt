defmodule Exfmt.Ast do
  @moduledoc false

  alias Exfmt.{Algebra, Context}
  alias __MODULE__.{Infix, Util}
  import Algebra
  require Algebra
  require Infix

  @doc """
  Converts Elixir AST into algebra that can be pretty printed.

  For more information on the Algebra used see the Exfmt.Algebra
  module.

  """
  @spec to_algebra(Macro.t, Context.t) :: Algebra.t
  def to_algebra(ast, context)

  #
  # Comments
  #
  def to_algebra({:"#", _, text}, _ctx) do
    concat("#", text)
  end

  #
  # Lists
  #
  def to_algebra(list, ctx) when is_list(list) do
    new_ctx = Context.push_stack(ctx, :list)
    with {:"[]", [_|_]} <- {:"[]", list},
         {:kw, true} <- {:kw, Inspect.List.keyword?(list)},
         {:cl, [:call | _]} <- {:cl, ctx.stack} do
      fun = &keyword_to_algebra(&1, &2, new_ctx)
      surround_many("", list, "", ctx.opts, fun)
    else
      {:kw, false} ->
        fun = fn(elem, _opts) -> to_algebra(elem, new_ctx) end
        surround_many("[", list, "]", ctx.opts, fun)

      {:cl, _} ->
        fun = &keyword_to_algebra(&1, &2, new_ctx)
        surround_many("[", list, "]", ctx.opts, fun)

      {:"[]", _} ->
        "[]"
    end
  end

  #
  # Maps
  #
  def to_algebra({:%{}, _, pairs}, ctx) do
    if Inspect.List.keyword?(pairs) do
      new_ctx = Context.push_stack(ctx, :keyword)
      fun = &keyword_to_algebra(&1, &2, new_ctx)
      surround_many("%{", pairs, "}", ctx.opts, fun)
    else
      new_ctx = Context.push_stack(ctx, :map)
      fun = fn({k, v}, _) ->
        concat(concat(to_algebra(k, ctx), " => "), to_algebra(v, new_ctx))
      end
      surround_many("%{", pairs, "}", ctx.opts, fun)
    end
  end

  #
  # Tuples
  #
  def to_algebra({:{}, _, elems}, ctx) do
    new_ctx = Context.push_stack(ctx, :tuple)
    fun = fn(elem, _opts) -> to_algebra(elem, new_ctx) end
    surround_many("{", elems, "}", ctx.opts, fun)
  end

  def to_algebra({a, b}, ctx) do
    to_algebra({:{}, [], [a, b]}, ctx)
  end

  #
  # Arity labelled functions
  #
  def to_algebra({:__block__, _, [head|tail]}, ctx) do
    fun = &line(&2, to_algebra(&1, ctx))
    Enum.reduce(tail, to_algebra(head, ctx), fun)
  end

  #
  # Captured functions
  #
  def to_algebra({:&, _, [arg]}, ctx) do
    new_ctx = Context.push_stack(ctx, :&)
    arg_algebra = to_algebra(arg, new_ctx)
    case arg do
      {:/, _, [_name, arity]} when is_integer(arity) ->
        concat("&", arg_algebra)

      {op, _, _} when op in Infix.infix_ops ->
        space("&", arg_algebra)

      _ ->
        concat("&", arg_algebra)
    end
  end

  #
  # fn -> ... end
  #
  def to_algebra({:fn, _, [{:->, _, [args, body]}]}, ctx) do
    new_ctx = Context.push_stack(ctx, :fn)
    head = fn_head_algebra(args, new_ctx)
    body_algebra = to_algebra(body, new_ctx)
    case body do
      {:__block__, _, _} ->
        line(nest(line(head, body_algebra), 2), "end")

      _single_expr ->
        glue(glue(head, body_algebra), "end")
    end
  end

  #
  # Arity labelled functions
  #
  def to_algebra({:/, _, [{name, _, nil}, arity]}, _ctx)
  when is_atom(name) and is_number(arity) do
    "#{name}/#{arity}"
  end

  #
  # @spec ::
  #
  def to_algebra({:::, _, [fun, result]}, ctx) do
    lhs_ctx = Context.push_stack(ctx, :spec_lhs)
    rhs_ctx = Context.push_stack(ctx, :spec_rhs)
    lhs = to_algebra(fun, lhs_ctx)
    rhs = to_algebra(result, rhs_ctx)
    glue(lhs, space("::", group(rhs)))
  end

  #
  # Infix operators
  #
  def to_algebra({op, _, [l, r]}, ctx) when op in Infix.infix_ops do
    new_ctx = Context.push_stack(ctx, op)
    lhs = infix_child_to_algebra(l, :left, new_ctx)
    rhs = infix_child_to_algebra(r, :right, new_ctx)
    case op do
      :|> ->
        glue(line(lhs, "|>"), rhs)

      :| ->
        glue(lhs, space("|", rhs))

      _ ->
        nest(glue(space(lhs, to_string(op)), rhs), 2)
    end
  end

  #
  # Negatives
  #
  def to_algebra({:-, _, [value]}, ctx) when value in [0, 0.0] do
    to_doc(value, ctx.opts)
  end

  def to_algebra({:-, _, [number]}, ctx) do
    new_ctx = Context.push_stack(ctx, :negative)
    concat("-", to_algebra(number, new_ctx))
  end

  #
  # Aliases
  #
  def to_algebra({:__aliases__, _, names}, _ctx) do
    names
    |> Enum.map(&to_string/1)
    |> Enum.join(".")
  end

  #
  # Anon function calls
  #
  def to_algebra({{:., _, [{name, _, nil}]}, meta, args}, ctx) do
    new_ctx = Context.push_stack(ctx, :call)
    fn_name = to_string(name) <> "."
    to_algebra({fn_name, meta, args}, new_ctx)
  end

  #
  # Module attributes
  #
  def to_algebra({:@, _, [{name, _, nil}]}, _ctx) do
    "@#{name}"
  end

  def to_algebra({:@, _, [{name, _, [value]}]}, ctx) do
    new_ctx = Context.push_stack(ctx, :module_attribute)
    len = String.length(to_string(name)) + 2
    concat("@#{name} ", nest(to_algebra(value, new_ctx), len))
  end

  #
  # Zero arity calls and variables
  #
  def to_algebra({name, _, nil}, _ctx) do
    to_string(name)
  end

  #
  # Access protocol
  #
  def to_algebra({{:., _, [Access, :get]}, _, [structure, key]}, ctx) do
    new_ctx = Context.push_stack(ctx, :access)
    algebra = to_algebra(structure, new_ctx)
    "#{algebra}[#{to_algebra(key, new_ctx)}]"
  end

  #
  # Zero arity qualified function calls
  #
  def to_algebra({{:., _, [aliases, name]}, _, []}, ctx) do
    new_ctx = Context.push_stack(ctx, :call)
    module = to_algebra(aliases, new_ctx)
    "#{module}.#{name}"
  end

  #
  # Group alias syntax
  # alias Pet.{Dog, Cat}
  #
  def to_algebra({{:., m, [aliases, :{}]}, _, args}, ctx) do
    new_ctx = Context.push_stack(ctx, :call)
    module = to_algebra(aliases, new_ctx) <> "."
    mod_len = String.length(module)
    concat(module, nest(to_algebra({:{}, m, args}, new_ctx), mod_len))
  end

  #
  # Qualified function calls
  #
  def to_algebra({{:., _, [aliases, name]}, _, args}, ctx) do
    new_ctx = Context.push_stack(ctx, :call)
    module = to_algebra(aliases, new_ctx)
    name = "#{module}.#{name}"
    call_to_algebra(name, args, new_ctx)
  end

  #
  # Function calls and sigils
  #
  def to_algebra({name, _, args}, ctx) do
    case to_string(name) do
      "sigil_" <> <<char::utf8>> ->
        new_ctx = Context.push_stack(ctx, :sigil)
        sigil_to_algebra(char, args, new_ctx)

      _ ->
        new_ctx = Context.push_stack(ctx, :call)
        call_to_algebra(name, args, new_ctx)
    end
  end

  #
  # Atoms, strings, numbers
  #
  def to_algebra(value, ctx)
  when is_atom(value) or is_binary(value) or is_number(value) do
    to_doc(value, ctx.opts)
  end

  #
  # Private
  #

  defp keyword_to_algebra({k, v}, _, ctx) do
    concat(concat(to_string(k), ": "), to_algebra(v, ctx))
  end

  def sigil_to_algebra(char, [{:<<>>, _, [contents]}, mods], _ctx) do
    {primary_open, primary_close, alt_open, alt_close} =
      case char do
        c when c in [?r, ?R] ->
          {"/", "/", "(", ")"}

        _ ->
          {"(", ")", "[", "]"}
      end
    {open, close} =
      if String.contains?(contents, primary_close) do
        {alt_open, alt_close}
      else
        {primary_open, primary_close}
      end
    ["~", char, open, Inspect.BitString.escape(contents, close), close, mods]
    |> IO.iodata_to_binary()
  end

  def call_to_algebra(name, all_args, ctx) do
    str_name = to_string(name)
    name_len = String.length(str_name)
    fun = fn(elem, _opts) -> to_algebra(elem, ctx) end
    {args, blocks} = Util.split_do_block(all_args)
    case %{args: args, blocks: blocks, stack: ctx.stack} do
      %{blocks: b} when b != [] ->
        arg_list = surround_many(" ", args, "", ctx.opts, fun)
        blocks_algebra = do_block_algebra(blocks, ctx)
        glue(concat(str_name, nest(arg_list, name_len)), blocks_algebra)

      %{args: []} ->
        concat(str_name, "()")

      %{args: [{:__block__, _, _} | _]} ->
        arg_list = surround_many("(", args, ")", ctx.opts, fun)
        concat(str_name, nest(arg_list, name_len))

      %{stack: [:call]} ->
        arg_list = surround_many(" ", args, "", ctx.opts, fun)
        concat(str_name, nest(arg_list, name_len))

      %{stack: [:call, :do | _]} ->
        arg_list = surround_many(" ", args, "", ctx.opts, fun)
        concat(str_name, nest(arg_list, name_len))

      _ ->
        arg_list = surround_many("(", args, ")", ctx.opts, fun)
        concat(str_name, nest(arg_list, name_len))
    end
  end

  def infix_child_to_algebra(child, side, ctx) do
    algebra = to_algebra(child, ctx)
    if Infix.wrap?(child, side, ctx) do
      concat("(", concat(algebra, ")"))
    else
      algebra
    end
  end

  defp fn_head_algebra(args, ctx) do
    case args do
      [] ->
        "fn->"

      _ ->
        glue(call_to_algebra("fn", args, ctx), "->")
    end
  end

  defp do_block_algebra(block_args, ctx) do
    new_ctx = Context.push_stack(ctx, :do)
    section_to_algebra = fn({k, body}) ->
      body_algebra = block_arg_body_to_algebra(body, new_ctx)
      nest(line(to_string(k), body_algebra), 2)
    end
    block_args
    |> Enum.map(section_to_algebra)
    |> Enum.reduce(&line(&2, &1))
    |> line("end")
  end

  defp block_arg_body_to_algebra(body, ctx) do
    stab? = fn
      {:->, _, _} -> true
      _ -> false
    end
    if is_list(body) and Enum.all?(body, stab?) do
      stabs_to_algebra(body, ctx)
    else
      to_algebra(body, ctx)
    end
  end

  defp stabs_to_algebra(stabs, ctx) do
    stabs
    |> Enum.map(&stab_to_algebra(&1, ctx))
    |> Enum.reduce(&line(concat(&2, "\n"), &1))
  end

  #
  # foo ->
  #   :foo
  #
  defp stab_to_algebra({_, _, [[match], body]}, ctx) do
    lhs = to_algebra(match, ctx)
    rhs = to_algebra(body, ctx)
    stab = space(lhs, "->")
    nest(line(stab, rhs), 2)
  end
end
