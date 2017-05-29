defmodule Exfmt do
  @moduledoc """
  Turning code into code, hopefully without breaking anything.

  """

  alias Exfmt.{Ast, Algebra, Comment, Context, SyntaxError}
  @max_width 80

  @doc ~S"""
  Format a string of Elixir source code.

      iex> format("[1,2,3]")
      {:ok, "[1, 2, 3]\n"}

  """
  @spec format(String.t, integer) :: {:ok, String.t} | SyntaxError.t
  def format(source, max_width \\ @max_width) do
    with {:ok, tree} <- Code.string_to_quoted(source),
         {:ok, comments} <- Comment.extract_comments(source) do
      {:ok, do_format(tree, comments, max_width)}
    else
      {:error, error} ->
        SyntaxError.exception(error)
    end
  end


  @doc ~S"""
  Format a string of Elixir source code, throwing an exception
  in the event of failure.

      iex> format!("[1,2,3]")
      "[1, 2, 3]\n"

  """
  @spec format!(String.t, integer) :: String.t
  def format!(source, max_width \\ @max_width) do
    case format(source, max_width) do
      %SyntaxError{} = error ->
        raise error

      {:ok, formatted} ->
        formatted
    end
  end


  @doc """
  Check that a string of source code conforms to the exfmt style.
  If formatting the source code would not result in the source code
  changing this function will return `:ok`.

  """
  @spec check(String.t, integer) :: :ok | {:format_error, String.t} | SyntaxError.t
  def check(source, max_width \\ @max_width) do
    with {:ok, formatted} <- format(source, max_width) do
      if source == formatted do
        :ok
      else
        {:format_error, formatted}
      end
    end
  end


  defp do_format(tree, comments, max_width) do
    comments
    |> Comment.merge(tree)
    |> Ast.to_algebra(Context.new)
    |> Algebra.format(max_width)
    |> IO.chardata_to_string()
    |> (& &1 <> "\n").()
  end
end
