defmodule Exfmt.Comment do
  @moduledoc """
  We leverage `Code.string_to_quoted/2` to get the AST from
  Elixir source code. This is great as it's maintained by
  the core team (i.e. not me). This is not great as it doesn't
  preserve comments, so we need to extract them ourselves and
  then merge them into the AST later.

  """

  @type t :: {:"#", [line: non_neg_integer], [String.t]}

  @doc """
  Extract comments from a string of Elixir source code.

  """
  @spec extract_comments(String.t) :: {:ok, [t]} | :error
  def extract_comments(src) do
    case tokenize(src) do
      {:ok, tokens} ->
        comments =
          tokens
          |> Enum.filter(&match?({:comment, _, _}, &1))
          |> Enum.map(&transform_comment/1)
          |> Enum.reverse()
        {:ok, comments}

      error ->
        error
    end
  end


  defp tokenize(src) do
    pid = spawn_link(fn -> store([]) end)
    src
    |> String.to_charlist()
    |> :elixir_tokenizer.tokenize(1, preserve_comments: send_comment(pid))
    send pid, {:gets, self()}
    receive do
      tokens ->
        {:ok, tokens}
    end
  end

  defp send_comment(pid) do
    fn (line, column, _tokens, comment, _rest) ->
        length = length(comment)
        comment_token = {:comment, {line, {column, column + length}, nil}, comment}
        send pid, {:put, comment_token}
    end
  end

  defp store(tokens) do
    receive do
      {:put, token} ->
        store([token | tokens])
      {:gets, pid} ->
        send pid, Enum.reverse(tokens)
    end
  end

  defp transform_comment({:comment, {line, _, _}, chars}) do
    content =
      chars
      |> tl()
      |> to_string()
    {:"#", [line: line], [content]}
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

  def merge(comments, {:__block__, _, [nil]}) do
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
end
