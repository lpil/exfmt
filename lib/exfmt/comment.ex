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

  defmacrop is_horizontal_space(c) do
    quote do
      unquote(c) in [?\t, ?\s]
    end
  end

  @scope {:elixir_tokenizer, :filename, [], true, false}

  alias :elixir_interpolation, as: Interp

  defp extract([?~, char, delim, delim, delim | src], line, comments)
  when is_letter(char) and is_quote(delim) do
    with {:ok, new_src, new_line} <- discard_heredoc(src, delim, line) do
      extract(new_src, new_line, comments)
    end
  end

  # Sigil
  defp extract([?~, char, delim | src], line, comments)
  when is_letter(char) and is_sigil_delim(delim) do
    end_char = sigil_terminator(delim)
    case Interp.extract(line, 0, @scope, is_downcase(char), src, end_char) do
      {new_line, _col, _parts, new_src} ->
        extract(new_src, new_line, comments)

      {:error, _reason} ->
        :error
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
      {:"#comment_block", [], [{:ok, [line: 1], []}, {:"#", [line: 1], []}]}

  """
  @spec merge([t], Macro.t) :: Macro.t
  def merge(comments, nil) do
    {:"#comment_block", [], Enum.reverse(comments)}
  end

  def merge(comments, ast) do
    case Macro.prewalk(ast, Enum.reverse(comments), &merge_node/2) do
      {merged, []} ->
        merged

      {merged, remaining_comments} ->
        {:"#comment_block", [], [merged | remaining_comments]}
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
        block = {:"#comment_block", [], earlier ++ [ast]}
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


  defp discard_heredoc(src, delim, line) do
    case discard_heredoc_line(src, delim) do
      {:ok, new_src} ->
        discard_heredoc(new_src, delim, line + 1)

      {:finished, new_src} ->
        {:ok, new_src, line}

      {:error, _reason} ->
        :error
    end
  end


  #
  # Discard spaces, then content
  #
  defp discard_heredoc_line([c | src], delim) when is_horizontal_space(c) do
    discard_heredoc_line(src, delim)
  end

  defp discard_heredoc_line([delim, delim, delim | src], delim) do
    {:finished, src}
  end

  defp discard_heredoc_line(src, delim) do
    discard_heredoc_line_content(src, delim)
  end


  #
  # Discard content
  #
  defp discard_heredoc_line_content([?\\, ?\\ | src], delim) do
    discard_heredoc_line_content(src, delim)
  end

  defp discard_heredoc_line_content([?\\, delim | src], delim) do
    discard_heredoc_line_content(src, delim)
  end

  defp discard_heredoc_line_content([delim, delim, delim | _], delim) do
    {:error, :misplaced_terminator}
  end

  defp discard_heredoc_line_content([?\r, ?\n | src], _) do
    {:ok, src}
  end

  defp discard_heredoc_line_content([?\n | src], _) do
    {:ok, src}
  end

  defp discard_heredoc_line_content([_ | src], delim) do
    discard_heredoc_line_content(src, delim)
  end

  defp discard_heredoc_line_content(_, _) do
    {:error, :eof}
  end
end
