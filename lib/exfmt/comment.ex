defmodule Exfmt.Comment do
  @moduledoc """
  We leverage `Code.string_to_quoted/2` to get the AST from
  Elixir source code. This is great as it's maintained by
  the core team (i.e. not me). This is not great as it doesn't
  preserve comments, so we need to extract them ourselves and
  then merge them into the AST later.

  """

  @type t :: {:"#", non_neg_integer, [String.t]}

  @doc """
  Extract comments from a string of Elixir source code.

  """
  @spec extract_comments(String.t) :: {:ok, [t]} | :error
  def extract_comments(src) do
    src
    |> to_charlist()
    |> extract(1, [])
  end


  #
  # Guard macros
  #
  defmacrop is_quote(c) do
    quote do
      unquote(c) in [?', ?"]
    end
  end

  defmacrop is_upcase(c) do
    quote do
      unquote(c) >= ?A and unquote(c) <= ?Z
    end
  end

  defmacrop is_downcase(c) do
    quote do
      unquote(c) >= ?a and unquote(c) <= ?z
    end
  end

  defmacrop is_letter(c) do
    quote do
      is_upcase(unquote(c)) or is_downcase(unquote(c))
    end
  end

  defmacrop is_sigil_delim(c) do
    quote do
      unquote(c) in [?/, ?<, ?", ?', ?[, ?(, ?{, ?|]
    end
  end

  @scope {:elixir_tokenizer, :filename, [], true, false}

  alias :elixir_interpolation, as: Interp


  # Sigil
  defp extract([?~, char, delim | src], line, comments)
  when is_letter(char) and is_sigil_delim(delim) do
    end_char = sigil_terminator(delim)
    case Interp.extract(line, 0, @scope, is_downcase(char), src, end_char) do
      {:error, _reason} ->
        :error

      {new_line, _col, _parts, new_src} ->
        extract(new_src, new_line, comments)
    end
  end

  # Char literal
  defp extract([??, c | src], line, comments) when is_quote(c) do
    extract(src, line, comments)
  end

  defp extract([c | src], line, comments) when is_quote(c) do
    discard_string(src, line, comments, c)
  end

  defp extract([?\n | src], line, comments) do
    extract(src, line + 1, comments)
  end

  defp extract([?# | src], line, comments) do
    {comment_text, rest} = split_comment(src, [])
    comment = {:"#", [line: line], [comment_text]}
    new_comments = [comment | comments]
    extract(rest, line + 1, new_comments)
  end

  defp extract([], _line, comments) do
    {:ok, comments}
  end

  defp extract([_ | src], line, comments) do
    extract(src, line, comments)
  end


  defp split_comment([?\n | src], contents) do
    {IO.iodata_to_binary(contents), src}
  end

  defp split_comment([], contents) do
    {IO.iodata_to_binary(contents), []}
  end

  defp split_comment([c | src], contents) do
    split_comment(src, [contents, c])
  end


  #
  # Consume and discard a String
  # Adapted from `:elixir_tokenizer.handle_strings/6`
  #
  defp discard_string(src, line, comments, delim) do
    col = 0
    case Interp.extract(line, col, @scope, true, src, delim) do
      {:error, _reason} ->
        :error

      {new_line, _new_col, _interp_parts, rest} ->
        extract(rest, new_line, comments)
    end
  end


  @doc """
  Merge the given comments into an Elixir abstract syntax tree.

      iex> comments = [{:"#", [line: 1], []}]
      ...> ast = {:ok, [line: 1], []}
      ...> merge(comments, ast)
      {:__block__, [], [{:ok, [line: 1], []}, {:"#", [line: 1], []}]}

  """
  @spec merge([t], Macro.t) :: Macro.t
  def merge(comments, nil) do
    {:__block__, [], Enum.reverse(comments)}
  end

  def merge(comments, ast) do
    case Macro.postwalk(ast, comments, &merge_node/2) do
      {merged, []} ->
        merged

      {{:__block__, meta, merged}, rest} ->
        {:__block__, meta, merged ++ rest}

      {merged, rest} ->
        {:__block__, [], [merged | rest]}
    end
  end


  defp merge_node(ast, []) do
    {ast, []}
  end

  defp merge_node(ast, comments) do
    ast_line = line(ast)
    before_node = fn(c) -> line(c) < ast_line end
    case Enum.split_while(comments, before_node) do
      {[], _} ->
        {ast, Enum.reverse(comments)}

      {earlier, rest} ->
        block = {:__block__, [], Enum.reverse(earlier) ++ [ast]}
        {block, rest}
    end
  end


  defp line({_, meta, _}) do
    meta[:line] || 0
  end

  defp line(_) do
    0
  end


  defp sigil_terminator(c) do
    case c do
      ?( ->
        ?)

      ?[ ->
        ?]

      ?{ ->
        ?}

      ?< ->
        ?>

      x ->
        x
    end
  end
end
