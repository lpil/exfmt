defmodule Exfmt.Comment do
  @moduledoc """
  We leverage `Code.string_to_quoted/2` to get the AST from
  Elixir source code. This is great as it's maintained by
  the core team (i.e. not me). This is not great as it doesn't
  preserve comments, so we need to extract them ourselves and
  then merge them into the AST later.

  """

  @type t :: {:"#", non_neg_integer, String.t}

  @doc """
  Extract comments from a string of Elixir source code.

  """
  @spec extract_comments(String.t) :: {:ok, [t]} | :error
  def extract_comments(src) do
    extract(to_charlist(src), 1, [])
  end


  defp extract([c | src], line, comments) when c in [?', ?"] do
    discard_string(src, line, comments, c)
  end

  defp extract([?\n | src], line, comments) do
    extract(src, line + 1, comments)
  end

  defp extract([?# | src], line, comments) do
    {comment_text, rest} = split_comment(src, [])
    comment = {:"#", [line: line], comment_text}
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
    scope = {:elixir_tokenizer, :filename, [], true, false}
    case :elixir_interpolation.extract(line, col, scope, true, src, delim) do
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
        {ast, comments}

      {earlier, rest} ->
        block = {:__block__, [], earlier ++ [ast]}
        {block, rest}
    end
  end


  defp line({_, meta, _}) do
    meta[:line] || 0
  end

  defp line(_) do
    0
  end
end
