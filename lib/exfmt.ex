defmodule Exfmt do
  @moduledoc """
  Exfmt, an opinionated Elixir source code formatter. 🌸

  aka The everyone's favourite Elixir-to-Elixir compiler.

  ## API

  Functions in this module can be considered part of Exfmt's
  public interface, and can be presumed stable. Functions exposed
  by other modules may change at any time without warning,
  especially before v1.0.0.

  """

  alias Exfmt.{Ast, Algebra, Comment, Context, SyntaxError, SemanticsError}
  @max_width 80

  @doc ~S"""
  Format a string of Elixir source code.

      iex> format("[1,2,3]")
      {:ok, "[1, 2, 3]"}

  This function performs a check to ensure the input and output
  are semantically equivalent.

  """
  @spec format(String.t, integer)
    :: {:ok, String.t}
    | SyntaxError.t
    | SemanticsError.t
  def format(source, max_width \\ @max_width) do
    with {:ok, formatted} <- unsafe_format(source, max_width) do
      original_ast = Code.string_to_quoted!(source)
      formatted_ast = Code.string_to_quoted!(formatted)
      if Ast.eq?(original_ast, formatted_ast) do
        {:ok, formatted}
      else
        SemanticsError.exception()
      end
    end
  rescue
    _ in Elixir.SyntaxError ->
      SemanticsError.exception()
  end


  @doc ~S"""
  Format a string of Elixir source code, throwing an exception
  in the event of failure.

      iex> format!("[1,2,3]")
      "[1, 2, 3]"

  This function performs a check to ensure the input and output
  are semantically equivalent.

  """
  @spec format!(String.t, integer) :: String.t
  def format!(source, max_width \\ @max_width) do
    case format(source, max_width) do
      {:ok, formatted} ->
        formatted

      error ->
        raise error
    end
  end


  @doc ~S"""
  Format a string of Elixir source code.

      iex> unsafe_format("[1,2,3]")
      {:ok, "[1, 2, 3]"}

  Unlike `format/2` and `format!/2` this code does not compare
  the semantics of the input and the output, so if there is a
  bug in `exfmt` it may semantically alter your code when
  reformatting it.

  """
  @spec unsafe_format(String.t, integer) :: {:ok, String.t} | SyntaxError.t
  def unsafe_format(source, max_width \\ @max_width) do
    leading_indent = leading_indent(source)
    leading_whitespace = leading_whitespace(source, leading_indent)
    trailing_whitespace = trailing_whitespace(source)

    with {:ok, tree} <- Code.string_to_quoted(source),
         {:ok, comments} <- Comment.extract_comments(source) do
      result =
        tree
        |> do_format(comments, max_width - leading_indent)
        |> add_leading_indent(leading_indent)
        |> add_trailing_whitespace(trailing_whitespace)
        |> add_leading_whitespace(leading_whitespace)
        |> strip_trailing_line_whitespace
      {:ok, result}
    else
      {:error, error} ->
        SyntaxError.exception(error)
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


  #
  # Private
  #
  defp do_format(tree, comments, max_width) do
    new_tree = Ast.preprocess(tree)
    comments
    |> Comment.merge(new_tree)
    |> Ast.to_algebra(Context.new)
    |> Algebra.format(max_width)
    |> IO.chardata_to_string()
  end


  defp leading_indent(source, indent \\ 0)
  defp leading_indent("\n" <> rest, indent) do
    leading_indent(rest, indent)
  end
  defp leading_indent(" " <> rest, indent) do
    leading_indent(rest, indent + 1)
  end
  defp leading_indent(_source, indent) do
    indent
  end


  defp add_leading_indent(source, indent) do
    source
    |> String.split("\n")
    |> Enum.map(&add_indent_to_line(&1, indent))
    |> Enum.join("\n")
  end


  defp add_indent_to_line(line, indent) do
    String.duplicate(" ", indent) <> line
  end


  defp leading_whitespace(source, indent) do
    regex_result = Regex.run(~r/\A(\s*)/m, source)
    [capture | _rest] = regex_result || [""]
    # remove leading indent from leading whitespace capture, as it gets added back anyway
    capture_len = String.length(capture)
    String.slice(capture, 0, capture_len - indent)
  end


  defp trailing_whitespace(source) do
    regex_result = Regex.run(~r/(\n\s*)\Z/m, source)
    [capture | _rest] = regex_result || [""]
    capture
  end


  defp add_leading_whitespace(source, leading_whitespace) do
    leading_whitespace <> source
  end


  defp add_trailing_whitespace(source, trailing_whitespace) do
    source <> trailing_whitespace
  end


  defp strip_trailing_line_whitespace(source) do
    source
    |> String.split("\n")
    |> Enum.map(&String.rstrip/1)
    |> Enum.join("\n")
  end
end
