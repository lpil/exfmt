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
    surround_many("[", list, "]",
                  ctx.opts,
                  fn(elem, _opts) -> to_algebra(elem, ctx) end)
  end

  #
  # Maps
  #
  def to_algebra({:%{}, _, pairs}, ctx) do
    fun =
      if Inspect.List.keyword?(pairs) do
        fn({k, v}, _) ->
          concat(concat(to_string(k), ": "), to_algebra(v, ctx))
        end
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
  # Function calls
  #
  def to_algebra({name, _, args}, ctx) do
    str_name = to_string(name)
    name_len = String.length(str_name)
    arg_list = surround_many("(", args, ")",
                             ctx.opts,
                             fn(elem, _opts) -> to_algebra(elem, ctx) end)
    concat(to_string(str_name), nest(arg_list, name_len))
  end

  #
  # Atoms, strings, numbers
  #
  def to_algebra(value, ctx)
  when is_atom(value) or is_binary(value) or is_number(value) do
    to_doc(value, ctx.opts)
  end
end
