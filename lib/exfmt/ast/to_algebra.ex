defmodule Exfmt.Ast.ToAlgebra do
  @moduledoc """
  Converting extended Elixir AST to printable Algebra.

  """

  alias Exfmt.{Ast, Algebra, Context}
  alias Ast.{Infix, Sigil, Util}
  import Algebra
  require Algebra
  require Infix

  defmacrop is_block(name) do
    quote do
      unquote(name) in [:__block__, :"#comment_block"]
    end
  end


  defmacrop is_func_def(name) do
    quote do
      unquote(name) in [:def, :defp, :defmacro, :defmacrop, :defdelegate]
    end
  end


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
  # Char literals
  #
  def to_algebra({:"#char", _, [?\\]}, _ctx) do
    ~S"?\\"
  end

  def to_algebra({:"#char", _, [int]}, _ctx) do
    to_string [?? | escape_char(int)]
  end

  #
  # Char literals
  #
  def to_algebra({:"#bin_heredoc", _, [bin]}, _ctx) do
    lines =
      bin
      |> String.split("\n")
      |> Enum.intersperse(line())
      |> concat()
    [~s("""), line(), lines, ~s(""")]
    |> concat()
  end

  #
  # Blocks
  #
  def to_algebra({name, _, []}, ctx) when is_block(name) do
    call_to_algebra("__block__", [], ctx)
  end

  def to_algebra({name, _, exprs}, ctx) when is_block(name) do
    exprs
    |> Enum.map(&to_algebra(&1, ctx))
    |> Enum.reduce(&line(&2, &1))
  end

  #
  # Anon functions in typespecs
  #    @type t :: (() -> term)
  #
  def to_algebra([{:->, _, [args, result]}], ctx) do
    new_ctx = Context.push_stack(ctx, :->)
    res_doc = to_algebra(result, ctx)
    fun = fn(elem) -> to_algebra(elem, new_ctx) end
    args_doc = surround_many("(", args, ")", fun)
    fun_doc = concat([args_doc, " ->", break(), res_doc])
    surround("(", fun_doc, ")")
  end

  #
  # Lists
  #
  def to_algebra([], _ctx) do
    "[]"
  end

  def to_algebra(list, ctx) when is_list(list) do
    new_ctx = Context.push_stack(ctx, :list)
    if Inspect.List.keyword?(list) do
      keyword_list_to_algebra(list, new_ctx)
    else
      list_to_algebra(list, new_ctx)
    end
  end

  #
  # Structs
  #
  def to_algebra({:%, _, [name, {:%{}, _, args}]}, ctx) do
    name_ctx = Context.push_stack(ctx, :struct_name)
    name = struct_name_to_algebra(name, name_ctx)
    body_doc =
      args
      |> map_body_to_algebra(ctx)
      |> nest(:current)
    surround(concat(["%", name, "{"]), body_doc, "}")
    |> group()
  end

  #
  # Maps
  #
  def to_algebra({:%{}, _, contents}, ctx) do
    new_ctx = Context.push_stack(ctx, :map)
    body_doc = map_body_to_algebra(contents, new_ctx)
    ["%{", nest(concat(break(""), body_doc), 2), break("", ","), "}"]
    |> concat()
    |> group()
  end

  #
  # Tuples
  #
  def to_algebra({:{}, _, elems}, ctx) do
    new_ctx = Context.push_stack(ctx, :tuple)
    fun = fn(elem) -> to_algebra(elem, new_ctx) end
    surround_many("{", elems, "}", fun)
  end

  def to_algebra({a, b}, ctx) do
    to_algebra({:{}, [], [a, b]}, ctx)
  end

  #
  # Charlist interpolation
  #
  def to_algebra({{:., _, to_charlist}, _, [{:<<>>, _, _} = expr]}, ctx)
  when to_charlist == [String, :to_charlist] do
    maybe_interp_to_algebra(expr, ctx, ?')
  end

  #
  # Binaries and string interpolation
  #
  def to_algebra({:<<>>, _, _} = expr, ctx) do
    maybe_interp_to_algebra(expr, ctx, ?")
  end

  #
  # Captured functions
  #
  def to_algebra({:&, _, [arg]}, ctx) do
    capture_to_algebra(arg, ctx)
  end

  #
  # fn -> ... end
  #
  def to_algebra({:fn, _, [{:->, _, [args, body]}]}, ctx) do
    new_ctx = Context.push_stack(ctx, :fn)
    head = fn_head_algebra(args, new_ctx)
    body_algebra = to_algebra(body, new_ctx)
    case body do
      {name, _, _} when is_block(name) ->
        line(nest(line(head, body_algebra), 2), "end")

      _single_expr ->
        glue(nest(glue(head, body_algebra), 2), "end")
    end
  end

  #
  # Multi-clause fn
  #
  def to_algebra({:fn, _, clauses}, ctx) do
    new_ctx = Context.push_stack(ctx, :fn)
    clauses_doc = clauses_to_algebra(clauses, new_ctx)
    line(nest(line("fn", clauses_doc), 2), "end")
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
    [lhs, break(), ":: ", group(rhs)]
    |> concat()
  end

  #
  # Infix operators
  #
  def to_algebra({op, _, [l, r]}, ctx) when op in Infix.infix_ops do
    new_ctx = Context.push_stack(ctx, op)
    lhs = infix_child_to_algebra(l, :left, new_ctx)
    rhs = infix_child_to_algebra(r, :right, new_ctx)
    case {op, ctx.stack} do
      {:/, [:& | _]} ->
        [lhs, "/", rhs]
        |> concat()

      {:|>, _} ->
        [lhs, line(), "|> ", rhs]
        |> concat()

      {:|, _} ->
        [lhs, break(), "| ", rhs]
        |> concat()

      {:.., _} ->
        [lhs, "..", rhs]
        |> concat()

      {:=, _} ->
        case r do
          # For Maps, we want to hold the opening brace next to the assignments
          # even when space constraints force a line break
          {:%{}, _, _} ->
            [lhs, " = ", rhs]
            |> concat()
            |> group()
          _ ->
            [lhs, " ", to_string(op), break(), rhs]
            |> concat()
            |> group()
            |> nest(2)
        end

      _ ->
        [lhs, " ", to_string(op), break(), rhs]
        |> concat()
        |> group()
        |> nest(2)
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
  # __aliases__/1
  #
  def to_algebra({:__aliases__, _, [{name, _, _}]}, _ctx) do
    "__aliases__(#{name})"
  end

  #
  # Aliases
  #
  def to_algebra({:__aliases__, _, names}, ctx) do
    names
    |> Enum.map(&alias_to_string(&1, ctx))
    |> Enum.intersperse(".")
    |> Enum.reduce(&concat(&2, &1))
  end

  #
  # Anon function immediately called
  # (&inspect/1).()
  #
  def to_algebra({{:., _, [{:&, _, _} = fun]}, _meta, args}, ctx) do
    new_ctx = Context.push_stack(ctx, :call)
    fun_doc = to_algebra(fun, new_ctx)
    callback = fn(elem) -> to_algebra(elem, ctx) end
    args_doc = surround_many("(", args, ")", callback)
    concat(surround("(", fun_doc, ")."), args_doc)
  end

  #
  # Anon function call
  #
  def to_algebra({{:., _, [name]}, _, args}, ctx) do
    new_ctx = Context.push_stack(ctx, :call)
    name_doc = to_algebra(name, new_ctx)
    args_doc = args_to_algebra(args, new_ctx, parens: true)
    [name_doc, ".", nest(args_doc, :current)]
    |> concat()
  end

  #
  # Module attributes
  #
  def to_algebra({:@, _, [{name, _, nil}]}, _ctx) do
    "@#{name}"
  end

  def to_algebra({:@, _, [{name, _, [value]}]}, ctx) do
    new_ctx = Context.push_stack(ctx, :module_attribute)
    head_doc = "@#{name}"
    value_doc = to_algebra(value, new_ctx)
    safe_value_doc = if Util.call_with_block?(value) do
      surround("(", value_doc, ")")
    else
      value_doc
    end
    space(head_doc, safe_value_doc)
  end

  #
  # Access protocol
  #
  def to_algebra({{:., _, [Access, :get]}, _, [structure, key]}, ctx) do
    new_ctx = Context.push_stack(ctx, :access)
    algebra = to_algebra(structure, new_ctx)
    surround(concat(algebra, "["), to_algebra(key, new_ctx), "]")
  end

  #
  # Accessing property of range struct
  #
  def to_algebra({{:., _, [{:.., _, _} = range, name]}, _, []}, ctx) do
    new_ctx = Context.push_stack(ctx, :call)
    range_doc = to_algebra(range, new_ctx)
    ["(", range_doc, ").#{name}"]
    |> concat()

  end

  #
  # Zero arity non-qualified calls and variables
  #   e.g. run, x
  #
  def to_algebra({name, _, nil}, _ctx) do
    to_string(name)
  end

  #
  # Zero arity qualified function calls to arity labeled function
  #   e.g. List.flatten/1
  #
  def to_algebra({{:., _, [aliases = {:__aliases__, _, _}, name]}, _, []}, ctx = %{stack: [:/ | _]}) do
    zero_arity_call_to_algebra(".#{name}", aliases, ctx)
  end

  #
  # Zero arity qualified function calls
  #   e.g. Mix.env(), String.t
  #
  def to_algebra({{:., _, [aliases = {:__aliases__, _, _}, name]}, _, []}, ctx) do
    name = case Context.stack_contains?(ctx, :spec_lhs) ||
                Context.stack_contains?(ctx, :spec_rhs) do
      true ->
        ".#{name}"

      _ ->
        ".#{name}()"
    end
    zero_arity_call_to_algebra(name, aliases, ctx)
  end

  #
  # Zero arity qualified function calls to atoms
  #   e.g. :random.uniform()
  #
  def to_algebra({{:., _, [aliases, name]}, _, []}, ctx) when is_atom(aliases) do
    zero_arity_call_to_algebra(".#{name}()", aliases, ctx)
  end

  #
  # Zero arity qualified access function calls
  #   e.g. conn.assigns[:safe_mode_active]
  #
  def to_algebra({{:., _, [aliases, name]}, _, []}, %{stack: [:access | _]} = ctx) do
    zero_arity_call_to_algebra(".#{name}", aliases, ctx)
  end

  #
  # Zero arity non-qualified function calls
  #   e.g. my_mod.get
  #
  def to_algebra({{:., _, [aliases, name]}, _, []}, ctx) do
    zero_arity_call_to_algebra(".#{name}", aliases, ctx)
  end

  #
  # Group alias syntax
  # alias Pet.{Dog, Cat}
  #
  def to_algebra({{:., m, [aliases, :{}]}, _, args}, ctx) do
    new_ctx = Context.push_stack(ctx, :call)
    module = concat(to_algebra(aliases, new_ctx), ".")
    concat(module, nest(to_algebra({:{}, m, args}, new_ctx), :current))
  end

  #
  # Qualified function calls
  #
  def to_algebra({{:., _, [aliases, name]}, _, args}, ctx) do
    new_ctx = Context.push_stack(ctx, :call)
    module = to_algebra(aliases, new_ctx)
    call = call_to_algebra(to_string(name), args, new_ctx)
    concat(concat(module, "."), call)
  end


  #
  # Zero arity function definitions without parens
  #   def say_hi do
  #     "hi"
  #   end
  #
  def to_algebra({name, _, args = [{_, _, nil}, _]}, ctx) when is_func_def(name) do
    args = List.replace_at(args, 0, put_elem(List.first(args), 2, []))
    new_ctx = Context.push_stack(ctx, :call)
    call_to_algebra(to_string(name), args, new_ctx)
  end

  #
  # Function calls and sigils
  #
  def to_algebra({name, _, args}, ctx) when is_binary(name) or is_atom(name) do
    case to_string(name) do
      "sigil_" <> <<char::utf8>> ->
        new_ctx = Context.push_stack(ctx, :sigil)
        sigil_to_algebra(char, args, new_ctx)

      str_name ->
        new_ctx = Context.push_stack(ctx, :call)
        call_to_algebra(str_name, args, new_ctx)
    end
  end

  #
  # Call with function name from call
  #   unquote(name)(arg)
  #
  def to_algebra({{_, _, _} = fun, _, args}, ctx) do
    new_ctx = Context.push_stack(ctx, :chain_call)
    fun_doc = to_algebra(fun, new_ctx)
    call_to_algebra(fun_doc, args, new_ctx)
  end

  #
  # Integers
  #
  def to_algebra(int, _ctx) when is_integer(int) do
    integer_to_algebra(int)
  end

  #
  # Strings, numbers, nil, booleans
  #
  def to_algebra(value, _ctx) when is_nil(value) or is_boolean(value) or
                                   is_binary(value) or is_number(value) do
    to_doc(value)
  end

  #
  # Atoms
  #
  def to_algebra(atom, _ctx) when is_atom(atom) do
    case Atom.to_string(atom) do
      ("Elixir" <> _) = string ->
        ~S(:") <> string <> ~S(")

      _ ->
        to_doc(atom)
    end
  end

  #
  # Private
  #

  defp arrow_pair_to_algebra({k, v}, ctx) do
    space(space(to_algebra(k, ctx), "=>"), to_algebra(v, ctx))
  end

  defp arrow_pair_to_algebra(value, ctx) do
    to_algebra(value, ctx)
  end


  defp keyword_to_algebra({k, v}, ctx) do
    name = atom_to_name(inspect(k))
    space(concat(name, ":"), to_algebra(v, ctx))
  end


  defp sigil_to_algebra(char, [{:<<>>, _, parts}, mods], ctx) do
    {open, close} = Sigil.delimiters(char, parts)
    content_doc = interp_to_algebra(parts, ctx, open, close, escape: :basic)
    open_doc = concat("~", List.to_string([char]))
    close_doc = List.to_string(mods)
    surround(open_doc, content_doc, close_doc)
  end

  defp sigil_to_algebra(char, args, ctx) do
    new_ctx = Context.push_stack(ctx, :call)
    call_to_algebra(IO.chardata_to_string(["sigil_", char]), args, new_ctx)
  end


  defp call_to_algebra("not", [arg], ctx) do
    new_ctx = Context.push_stack(ctx, :call)
    space("not", to_algebra(arg, new_ctx))
  end

  defp call_to_algebra(name, all_args, ctx) do
    {args, blocks} = Util.split_do_block(all_args)
    data = %{args: args, blocks: blocks, stack: ctx.stack}
    case data do
      # "Zero" arity call with block args
      %{args: [], blocks: b} when b != [] ->
        blocks_algebra = do_block_algebra(blocks, ctx)
        space(name, blocks_algebra)

      # Call with block args
      %{blocks: b} when b != [] ->
        args_with_block? = Enum.any?(args, &Util.call_with_block?/1)
        arg_list = args_to_algebra(args, ctx, parens: args_with_block?, space: !args_with_block?)
        blocks_algebra = do_block_algebra(blocks, ctx)
        space(concat(name, nest(arg_list, :current)), blocks_algebra)

      # Zero arity call
      %{args: []} ->
        concat(name, "()")

      # Block arg
      %{args: [{arg_name, _, _} | _]} when is_block(arg_name) ->
        arg_list = args_to_algebra(args, ctx)
        concat(name, nest(arg_list, :current))

      # Top level call
      %{stack: [:call]} ->
        args_with_block? = Enum.any?(args, &Util.call_with_block?/1)
        arg_list = args_to_algebra(args, ctx, parens: args_with_block?, space: !args_with_block?)
        concat(name, nest(arg_list, :current))

      # Call inside a do end block
      %{stack: [:call, :do | _]} ->
        args_with_block? = Enum.any?(args, &Util.call_with_block?/1)
        arg_list = args_to_algebra(args, ctx, parens: args_with_block?, space: !args_with_block?)
        concat(name, nest(arg_list, :current))

      %{stack: [:fn | _], args: args} ->
        arg_list = args_to_algebra(args, ctx, parens: false)
        space(name, nest(arg_list, :current))

      _ ->
        arg_list = args_to_algebra(args, ctx)
        concat(name, nest(arg_list, :current))
    end
  end

  defp zero_arity_call_to_algebra(name, aliases, ctx) do
    new_ctx = Context.push_stack(ctx, :call)
    module = to_algebra(aliases, new_ctx)
    concat(module, name)
  end

  #
  # TODO: The `space` and `parens` options are pretty grim.
  # Perhaps split this out into just forming of the arguments,
  # and leave the wrapping of parens to another function.
  #
  defp args_to_algebra(args, ctx, opts \\ [parens: true])

  defp args_to_algebra([{:when, _, args}], ctx, opts) do
    new_ctx = Context.push_stack(ctx, :when)
    {call_args, [guard]} = Enum.split(args, -1)
    args_doc = args_to_algebra(call_args, ctx, opts)
    guard_doc = to_algebra(guard, new_ctx)
    [args_doc, group(nest(glue("", group(space("when", guard_doc))), 1))]
    |> concat()
  end

  defp args_to_algebra(args, ctx, opts) do
    count = length(args)
    {open, close} = if opts[:parens] do
      {"(", ")"}
    else
      {"", ""}
    end
    indexed = Enum.with_index(args, 1)
    fun = fn(arg) -> arg_to_algebra(count, arg, ctx) end
    doc = surround_many(open, indexed, close, fun)
    if opts[:space] do
      concat(" ", doc)
    else
      doc
    end
  end


  defp arg_to_algebra(num_args, {arg, num_args}, ctx) do
    new_ctx = Context.push_stack(ctx, :last_arg)
    to_algebra(arg, new_ctx)
  end

  defp arg_to_algebra(_num_args, {arg, _number}, ctx) do
    to_algebra(arg, ctx)
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
        "fn ->"

      _ ->
        space(call_to_algebra("fn", args, ctx), "->")
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


  defp block_arg_body_to_algebra([], _ctx) do
    "[]"
  end

  defp block_arg_body_to_algebra(body, ctx) do
    if is_list(body) and Enum.all?(body, &stab?/1) do
      clauses_to_algebra(body, ctx)
    else
      to_algebra(body, ctx)
    end
  end


  defp stab?({:"#comment_block", _, exprs}) do
    Enum.all?(exprs, fn
      {:"#", _, _} ->
        true

      {:->, _, _} ->
        true

      _ ->
        false
    end)
  end

  defp stab?({:->, _, _}) do
    true
  end

  defp stab?(_) do
    false
  end


  defp clauses_to_algebra(stabs, ctx) do
    stabs
    |> Enum.map(&clause_to_algebra(&1, ctx))
    |> Enum.reduce(&line(concat(&2, "\n"), &1))
  end


  #
  # foo ->
  #   :foo
  #
  defp clause_to_algebra({:->, _, [args, body]}, ctx) do
    lhs = args_to_algebra(args, ctx, parems: false)
    rhs = to_algebra(body, ctx)
    [lhs, " ->", line(), rhs]
    |> concat()
    |> nest(2)
  end

  defp clause_to_algebra({:"#comment_block", _, [first | rest]}, ctx) do
    to_doc = fn
      {:"#", _, _} = comment ->
        to_algebra(comment, ctx)

      stab ->
        clause_to_algebra(stab, ctx)
    end
    first_doc = to_doc.(first)
    Enum.reduce rest, first_doc, fn(expr, acc) ->
      expr_doc = to_doc.(expr)
      line(acc, expr_doc)
    end
  end


  defp map_body_to_algebra([{:|, _, [name, pairs]}], ctx) do
    name_doc = to_algebra(name, ctx)
    pairs_doc = map_pairs_to_algebra(pairs, ctx)
    [name_doc, " |", break(), pairs_doc]
    |> concat()
  end

  defp map_body_to_algebra(pairs, ctx) do
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
      [acc, ",", break(), doc]
      |> concat()
    end
    Enum.reduce(pairs, first_doc, reducer)
  end


  defp interp_to_algebra(parts, ctx, open, close, opts \\ []) do
    merge = fn
      ({:::, _, [{{:., _, _}, _, [content]}, {:binary, _, nil}]}, acc) ->
        content_doc = to_algebra(content, ctx)
        interp_doc = surround("#\{", content_doc, "}")
        concat(acc, interp_doc)

      (string, acc) ->
        doc =
          case opts[:escape] || :all do
            :all ->
              binary_full_escape(string, close, [])

            _ ->
              binary_escape(string, close, [])
          end
        concat(acc, doc)
    end
    inner_doc = Enum.reduce(parts, empty(), merge)
    surround(List.to_string([open]), inner_doc, List.to_string([close]))
  end


  @slash ?\\
  @escape_chars [{?\n, ?n}, {?\r, ?r}, {?\t, ?t}, {?\v, ?v}, {?\b, ?b},
                 {?\f, ?f}, {?\e, ?e}, {?\d, ?d}, {?\a, ?a}]

  for {char, escaped} <- @escape_chars do
    defp binary_full_escape(<<unquote(char), rest::binary>>, close, acc) do
      binary_escape(rest, close, [acc, @slash, unquote(escaped)])
    end
  end


  for {char, escaped} <- @escape_chars do
    defp escape_char(unquote(char)) do
      [@slash, unquote(escaped)]
    end
  end

  defp escape_char(c) do
    [c]
  end


  for name <- [:binary_full_escape, :binary_escape] do
    defp unquote(name)(<<>>, _close, acc) do
      IO.chardata_to_string(acc)
    end

    defp unquote(name)(<<@slash, @slash, rest::binary>>, close, acc) do
      unquote(name)(rest, close, [acc, @slash, @slash])
    end

    defp unquote(name)(<<@slash, close::utf8, rest::binary>>, close, acc) do
      unquote(name)(rest, close, [acc, @slash, @slash, @slash, close])
    end

    defp unquote(name)(<<close::utf8, rest::binary>>, close, acc) do
      unquote(name)(rest, close, [acc, @slash, close])
    end

    defp unquote(name)(<<char::utf8, rest::binary>>, close, acc) do
      unquote(name)(rest, close, [acc, char])
    end

    defp unquote(name)(<<char::utf16, rest::binary>>, close, acc) do
      unquote(name)(rest, close, [acc, char])
    end
  end


  defp alias_to_string({:__MODULE__, _, _}, _ctx) do
    "__MODULE__"
  end

  defp alias_to_string(atom, _ctx) when is_atom(atom) do
    to_string(atom)
  end

  defp alias_to_string(expr, ctx) do
    to_algebra(expr, ctx)
  end


  defp interpolated?({:<<>>, _, [_ | _] = parts}) do
    interp? =
      &match?({:::, _, [{{:., _, [Kernel, :to_string]}, _, [_]}, {:binary, _, _}]},
              &1)
    Enum.any?(parts, interp?)
  end

  defp interpolated?(_) do
    false
  end


  defp bitpart_to_algebra({:::, _, [left, right]}, ctx) do
    new_ctx = Context.push_stack(ctx, :::)
    lhs_doc = to_algebra(left, new_ctx)
    rhs_doc = to_algebra(right, new_ctx)
    surround(lhs_doc, "::", group(rhs_doc))
  end

  defp bitpart_to_algebra({:<-, _, _} = part, ctx) do
    new_ctx = Context.push_stack(ctx, :<-)
    doc = to_algebra(part, new_ctx)
    nest(surround("(", doc, ")"), 1)
  end

  defp bitpart_to_algebra(part, ctx) do
    new_ctx = Context.push_stack(ctx, :::)
    to_algebra(part, new_ctx)
  end


  defp bitparts_to_algebra([], ctx) do
    binary_delim empty(), ctx
  end

  defp bitparts_to_algebra([first | rest], ctx) do
    first_doc = bitpart_to_algebra(first, ctx)
    reduce = fn(part, acc) ->
      doc = bitpart_to_algebra(part, ctx)
      glue(concat(acc, ","), doc)
    end
    rest
    |> Enum.reduce(first_doc, reduce)
    |> binary_delim(ctx)
  end


  defp binary_delim(doc, ctx) do
    case ctx.stack do
      [:<<>>, :::, :<<>> | _] ->
        group(nest(surround("(<<", doc, ">>)"), 2))

      _ ->
        group(nest(surround("<<", doc, ">>"), 1))
    end
  end


  defp maybe_interp_to_algebra({:<<>>, _, parts} = expr, ctx, delim) do
    if interpolated?(expr) do
      interp_to_algebra(parts, ctx, delim, delim)
    else
      new_ctx = Context.push_stack(ctx, :<<>>)
      bitparts_to_algebra(parts, new_ctx)
    end
  end


  defp capture_to_algebra(arg, ctx) do
    new_ctx = Context.push_stack(ctx, :&)
    arg_algebra = to_algebra(arg, new_ctx)
    case arg do
      # & &&/2
      {:/, _, [{:&&, _, _}, arity]} when is_integer(arity) ->
        space("&", arg_algebra)

      # &run/1
      {:/, _, [_name, arity]} when is_integer(arity) ->
        concat("&", arg_algebra)

      # & &1.key
      {{:., _, [{:&, _, _} | _]}, _, _} ->
        space("&", arg_algebra)

      # & &1 + &2
      {op, _, _} when op in Infix.infix_ops ->
        space("&", arg_algebra)

      # & %{&1 | state: :ok}
      {:%{}, _, _} ->
        space("&", arg_algebra)

      # & &1[:key]
      {{:., _, [Access, :get]}, _, _} ->
        space("&", arg_algebra)

      # & &1
      {:&, _, _} ->
        space("&", arg_algebra)

      _ ->
        concat("&", arg_algebra)
    end
  end


  defp atom_to_name(":" <> name) do
    name
  end

  defp atom_to_name(name) do
    name
  end


  defp struct_name_to_algebra({:^, _, [name]}, ctx) do
    "^#{to_algebra(name, ctx)}"
  end

  defp struct_name_to_algebra(name, ctx) do
    to_algebra(name, ctx)
  end


  defp integer_to_algebra(int) when int < 100_000 do
    to_doc int
  end

  defp integer_to_algebra(int) do
    int
    |> to_doc()
    |> String.to_charlist()
    |> Enum.reverse()
    |> Enum.chunk_every(3, 3, [])
    |> Enum.join("_")
    |> String.reverse()
  end

  defp keyword_list_to_algebra(list, ctx) do
    case ctx.stack do
      [:list, :last_arg | _] ->
        list
        |> Enum.map(&keyword_to_algebra(&1, ctx))
        |> elem_docs_to_algebra()
        |> group()

      _ ->
        list
        |> Enum.map(&keyword_to_algebra(&1, ctx))
        |> elem_docs_to_algebra()
        |> wrap_list_algebra()
    end
  end

  defp list_to_algebra(list, ctx) do
    list
    |> Enum.map(&to_algebra(&1, ctx))
    |> elem_docs_to_algebra()
    |> wrap_list_algebra()
  end

  defp wrap_list_algebra(elems_doc) do
    contents_doc =
      [break(""), elems_doc]
      |> concat
      |> nest(2)
    ["[", contents_doc, break("", ","), "]"]
    |> concat()
    |> group()
  end

  defp elem_docs_to_algebra(elems) do
    elems
    |> Enum.intersperse(concat(",", break()))
    |> concat()
  end
end
