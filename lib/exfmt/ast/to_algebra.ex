defmodule Exfmt.Ast.ToAlgebra do
  @moduledoc """
  Converting extended Elixir AST to printable Algebra.

  """

  alias Exfmt.{Ast, Algebra, Context}
  alias Ast.{Infix, Util}
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
  def to_algebra({:"#", _, [text]}, _ctx) do
    concat("#", text)
  end

  #
  # Empty lines
  #
  def to_algebra({:"#newline", _, _}, _ctx) do
    empty()
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
  # Structs
  #
  def to_algebra({:%, _, [{:__MODULE__, _, _}, {:%{}, _, args}]}, ctx) do
    body_doc = map_body_to_algebra(args, ctx)
    group(nest(concat("%__MODULE__{", concat(body_doc, "}")), 12))
  end

  def to_algebra({:%, _, [{:__aliases__, _, mods}, {:%{}, _, args}]}, ctx) do
    name =
      mods
      |> Enum.map(&to_string/1)
      |> Enum.intersperse(".")
      |> IO.iodata_to_binary()
    indent = String.length(name) + 2
    start = concat(concat("%", name), "{")
    body_doc = map_body_to_algebra(args, ctx)
    group(nest(concat(start, concat(body_doc, "}")), indent))
  end

  #
  # Maps
  #
  def to_algebra({:%{}, _, contents}, ctx) do
    body_doc = map_body_to_algebra(contents, ctx)
    group(nest(glue("%{", "", concat(body_doc, "}")), 2))
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
  # String interpolation
  #
  def to_algebra({:<<>>, _, [{:::, _, _} | _] = parts}, ctx) do
    interp_to_algebra(parts, ctx)
  end

  def to_algebra({:<<>>, _, [_, {:::, _, _} | _] = parts}, ctx) do
    interp_to_algebra(parts, ctx)
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
      # &run/1
      {:/, _, [_name, arity]} when is_integer(arity) ->
        concat("&", arg_algebra)

      # & &1.key
      {{:., _, [{:&, _, _} | _]}, _, _} ->
        space("&", arg_algebra)

      # & &1 + &2
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
  # Anon function immediately called
  # (&inspect/1).()
  #
  def to_algebra({{:., _, [{:&, _, _} = fun]}, _meta, args}, ctx) do
    new_ctx = Context.push_stack(ctx, :call)
    fun_doc = to_algebra(fun, new_ctx)
    callback = fn(elem, _opts) -> to_algebra(elem, ctx) end
    args_doc = surround_many("(", args, ")", ctx.opts, callback)
    concat(concat(concat("(", fun_doc), ")."), args_doc)
  end

  #
  # Anon function call
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
    concat(module, ".#{name}")
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
  def to_algebra({name, _, args}, ctx) when is_binary(name) or is_atom(name) do
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

  defp arrow_pair_to_algebra({k, v}, ctx) do
    concat(concat(to_algebra(k, ctx), " => "), to_algebra(v, ctx))
  end

  defp keyword_to_algebra({k, v}, ctx) do
    concat(concat(to_string(k), ": "), to_algebra(v, ctx))
  end

  defp keyword_to_algebra(pair, _, ctx) do
    keyword_to_algebra(pair, ctx)
  end

  def sigil_to_algebra(char, [{:<<>>, _, [contents]}, mods], _ctx) do
    {primary_open, primary_close, alt_open, alt_close} =
      case char do
        c when c in [?r, ?R] ->
          {?/, ?/, ?(, ?)}

        _ ->
          {?(, ?), ?[, ?]}
      end
    {open, close} =
      if String.contains?(contents, IO.chardata_to_string([primary_close])) do
        {alt_open, alt_close}
      else
        {primary_open, primary_close}
      end
    ["~", char, open, Inspect.BitString.escape(contents, close), close, mods]
    |> IO.iodata_to_binary()
  end

  defp call_to_algebra(name, all_args, ctx) do
    str_name = to_string(name)
    name_len = String.length(str_name)
    fun = fn(elem, _opts) -> to_algebra(elem, ctx) end
    {args, blocks} = Util.split_do_block(all_args)
    data = %{args: args, blocks: blocks, stack: ctx.stack}
    case data do
      # Call with block args
      %{blocks: b} when b != [] ->
        arg_list = surround_many(" ", args, "", ctx.opts, fun)
        blocks_algebra = do_block_algebra(blocks, ctx)
        glue(concat(str_name, nest(arg_list, name_len)), blocks_algebra)

      # Zero arity call
      %{args: []} ->
        concat(str_name, "()")

      # Block arg
      %{args: [{:__block__, _, _} | _]} ->
        arg_list = surround_many("(", args, ")", ctx.opts, fun)
        concat(str_name, nest(arg_list, name_len))

      # Top level call
      %{stack: [:call]} ->
        arg_list = surround_many(" ", args, "", ctx.opts, fun)
        concat(str_name, nest(arg_list, name_len))

      # Call inside a do end block
      %{stack: [:call, :do | _]} ->
        arg_list = surround_many(" ", args, "", ctx.opts, fun)
        concat(str_name, nest(arg_list, name_len))

      _ ->
        arg_list = surround_many("(", args, ")", ctx.opts, fun)
        concat(str_name, nest(arg_list, name_len))
    end
  end


  defp infix_child_to_algebra(child, side, ctx) do
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


  def map_body_to_algebra([{:|, _, [{name, _, _}, pairs]}], ctx) do
    pairs_doc = map_pairs_to_algebra(pairs, ctx)
    glue(space(to_string(name), "|"), pairs_doc)
  end

  def map_body_to_algebra(pairs, ctx) do
    map_pairs_to_algebra(pairs, ctx)
  end


  defp map_pairs_to_algebra(pairs, ctx) do
    if Inspect.List.keyword?(pairs) do
      new_ctx = Context.push_stack(ctx, :keyword)
      pairs_to_algebra(pairs, &keyword_to_algebra/2, new_ctx)
    else
      new_ctx = Context.push_stack(ctx, :map)
      pairs_to_algebra(pairs, &arrow_pair_to_algebra/2, new_ctx)
    end
  end


  defp pairs_to_algebra([], _fun, _ctx) do
    empty()
  end

  defp pairs_to_algebra([first | pairs], pair_formatter, ctx) do
    first_doc = pair_formatter.(first, ctx)
    reducer = fn(pair, acc) ->
      doc = pair_formatter.(pair, ctx)
      glue(concat(acc, ","), doc)
    end
    Enum.reduce(pairs, first_doc, reducer)
  end


  defp interp_to_algebra(parts, ctx) do
    merge = fn
      ({:::, _, [{{:., _, _}, _, [content]}, {:binary, _, nil}]}, acc) ->
        content_doc = to_algebra(content, ctx)
        interp_doc = concat(concat("#\{", content_doc), "}")
        concat(acc, interp_doc)

      (string, acc) ->
        concat(acc, string)
    end
    inner_doc = Enum.reduce(parts, empty(), merge)
    concat(concat("\"", inner_doc), "\"")
  end
end
