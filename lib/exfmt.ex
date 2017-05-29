defmodule Exfmt do
  @moduledoc """
  Turning code into code, hopefully without breaking anything.

  """

  alias Exfmt.{Ast, Algebra, Comment, Context}

  @spec format(String.t, integer) :: String.t
  def format(source, max_width \\ 100) do
    {:ok, tree} = Code.string_to_quoted(source)
    {:ok, comments} = Comment.extract_comments(source)
    comments
    |> Comment.merge(tree)
    |> Ast.to_algebra(Context.new)
    |> Algebra.format(max_width)
    |> IO.chardata_to_string()
    |> (& &1 <> "\n").()
  end
end
