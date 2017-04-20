defmodule Exfmt.AST do
  alias Exfmt.Context
  alias Inspect.Algebra

  require Algebra
  import Algebra

  @spec to_algebra(Macro.t, Context.t) :: Algebra.t
  def to_algebra(ast, context)

  #
  # Lists
  #
  def to_algebra(list, ctx) when is_list(list) do
    fun =
      if Inspect.List.keyword?(list) do
        &keyword_to_algebra(&1, &2, ctx)
      else
        fn(elem, _opts) -> to_algebra(elem, ctx) end
      end
    surround_many("[", list, "]", ctx.opts, fun)
  end

  #
  # Maps
  #
  def to_algebra({:%{}, _, pairs}, ctx) do
    fun =
      if Inspect.List.keyword?(pairs) do
        &keyword_to_algebra(&1, &2, ctx)
      else
        fn({k, v}, _) ->
          concat(concat(to_algebra(k, ctx), " => "), to_algebra(v, ctx))
        end
      end
    surround_many("%{", pairs, "}", ctx.opts, fun)
  end

  #
  # Tuples
  #
  def to_algebra({:{}, _, elems}, ctx) do
    surround_many("{", elems, "}",
                  ctx.opts,
                  fn(elem, _opts) -> to_algebra(elem, ctx) end)
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
  # Negatives
  #
  def to_algebra({:-, _, [0]}, _ctx) do
    "0"
  end

  def to_algebra({:-, _, [number]}, ctx) do
    concat("-", to_algebra(number, ctx))
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
    fn_name = to_string(name) <> "."
    to_algebra({fn_name, meta, args}, ctx)
  end

  #
  # Module attributes
  #
  def to_algebra({:@, _, [{name, _, nil}]}, _ctx) do
    "@#{name}"
  end

  def to_algebra({:@, _, [{name, _, [value]}]}, ctx) do
    len = String.length(to_string(name)) + 2
    concat("@#{name} ", nest(to_algebra(value, ctx), len))
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
    algebra = to_algebra(structure, ctx)
    "#{algebra}[#{to_algebra(key, ctx)}]"
  end

  #
  # Zero arity qualified function calls
  #
  def to_algebra({{:., _, [aliases, name]}, _, []}, ctx) do
    module = to_algebra(aliases, ctx)
    "#{module}.#{name}"
  end

  #
  # Qualified function calls
  #
  def to_algebra({{:., _, [aliases, name]}, _, args}, ctx) do
    module = to_algebra(aliases, ctx)
    name = "#{module}.#{name}"
    call_to_algebra(name, args, ctx)
  end

  #
  # Function calls and sigils
  #
  def to_algebra({name, _, args}, ctx) do
    case to_string(name) do
      "sigil_" <> <<char::utf8>> ->
        sigil_to_algebra(char, args, ctx)
      str_name ->
        call_to_algebra(str_name, args, ctx)
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
    name_len = String.length(name)
    fun = fn(elem, _opts) -> to_algebra(elem, ctx) end
    arg_list = surround_many("(", args, ")", ctx.opts, fun)
    concat(name, nest(arg_list, name_len))
  end
end
