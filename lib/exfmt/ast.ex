defmodule Exfmt.AST do
  alias Exfmt.Context
  alias Inspect.Algebra

  require Algebra
  import Algebra

  defmacrop is_call(c) do
    quote do
      unquote(c) in [:call, :no_param_call]
    end
  end

  @spec to_algebra(Macro.t, Context.t) :: Algebra.t
  def to_algebra(ast, context)

  #
  # Lists
  #
  def to_algebra(list, ctx) when is_list(list) do
    new_ctx = Context.push_stack(ctx, :list)
    with {:"[]", [_|_]} <- {:"[]", list},
         {:kw, true} <- {:kw, Inspect.List.keyword?(list)},
         {:cl, [c | _]} when is_call(c) <- {:cl, ctx.stack} do
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
  # Functions
  #
  def to_algebra({:/, _, [{name, _, nil}, arity]}, _ctx)
  when is_atom(name) and is_number(arity) do
    "#{name}/#{arity}"
  end

  #
  # Addition, subtraction
  #
  def to_algebra({op, _, [l, r]}, ctx) when op in [:+, :-] do
    new_ctx = Context.push_stack(ctx, op)
    lhs = to_algebra(l, new_ctx)
    rhs = to_algebra(r, new_ctx)
    algebra = nest(glue(concat(lhs, " #{op}"), rhs), 2)
    case ctx.stack do
      [o | _] when o in [:/, :*] ->
        nest(concat("(", concat(algebra, ")")), 1)

      _ ->
        algebra
    end
  end

  #
  # Multiplication, division
  #
  def to_algebra({op, _, [l, r]}, ctx) when op in [:/, :*] do
    new_ctx = Context.push_stack(ctx, op)
    lhs = to_algebra(l, new_ctx)
    rhs = to_algebra(r, new_ctx)
    nest(glue(concat(lhs, " #{op}"), rhs), 2)
  end

  #
  # Negatives
  #
  def to_algebra({:-, _, [value]}, _ctx) when value in [0, 0.0] do
    to_string(value)
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
  def to_algebra({name, _, nil}, ctx) do
    case ctx.stack do
      [:spec_lhs|_] ->
        to_string(name) <> "()"

      _ ->
        to_string(name)
    end
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
  # @spec ::
  #
  def to_algebra({:::, _, [fun, result]}, ctx) do
    lhs_ctx = Context.push_stack(ctx, :spec_lhs)
    rhs_ctx = Context.push_stack(ctx, :spec_rhs)
    lhs = to_algebra(fun, lhs_ctx)
    rhs = to_algebra(result, rhs_ctx)
    glue(concat(lhs, " ::"), nest(rhs, 2))
  end

  #
  # | (@spec, list patterns)
  #
  def to_algebra({:|, _, [l, r]}, ctx) do
    lhs = to_algebra(l, ctx)
    rhs = to_algebra(r, ctx)
    glue(concat(lhs, " |"), rhs)
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
  @no_param_calls ~w(alias require import doctest defstruct)a
  def to_algebra({name, _, args}, ctx) do
    case to_string(name) do
      "sigil_" <> <<char::utf8>> ->
        new_ctx = Context.push_stack(ctx, :sigil)
        sigil_to_algebra(char, args, new_ctx)

      str_name when name in @no_param_calls ->
        new_ctx = Context.push_stack(ctx, :no_param_call)
        call_to_algebra(str_name, args, new_ctx)

      str_name ->
        new_ctx = Context.push_stack(ctx, :call)
        call_to_algebra(str_name, args, new_ctx)
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

  def call_to_algebra(name, args, ctx) do
    {open, close} = case ctx.stack do
      [:no_param_call | _] ->
        {" ", ""}

      _ ->
        {"(", ")"}
    end
    name_len = String.length(name)
    fun = fn(elem, _opts) -> to_algebra(elem, ctx) end
    arg_list = surround_many(open, args, close, ctx.opts, fun)
    concat(name, nest(arg_list, name_len))
  end
end
