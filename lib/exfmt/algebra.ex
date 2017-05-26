defmodule Exfmt.Algebra do
  @moduledoc """
  A set of functions for creating and manipulating algebra
  documents.

  This module implements the functionality described in
  ["Strictly Pretty" (2000) by Christian Lindig][0].

  [0]: http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.34.2200

  It serves an alternative printer to the one defined in
  `Inspect.Algebra`, which is part of the Elixir standard library
  but does not entirely conform to the algorithm described by Christian
  Lindig in a way that makes it unsuitable for use in ExFmt.

  """

  alias Inspect, as: I
  require I.Algebra

  defdelegate empty(), to: I.Algebra
  defdelegate break(), to: I.Algebra
  defdelegate break(doc), to: I.Algebra
  defdelegate concat(doc), to: I.Algebra
  defdelegate concat(doc1, doc2), to: I.Algebra
  defdelegate glue(doc1, doc2), to: I.Algebra
  defdelegate glue(doc1, sep, doc2), to: I.Algebra
  defdelegate fold_doc(docs, fun), to: I.Algebra
  defdelegate group(doc), to: I.Algebra
  defdelegate line(doc1, doc2), to: I.Algebra
  defdelegate nest(doc, level), to: I.Algebra
  defdelegate space(doc1, doc2), to: I.Algebra
  defdelegate surround(left, doc, right), to: I.Algebra
  defdelegate surround_many(l, docs, r, opts, fun), to: I.Algebra
  defdelegate surround_many(l, docs, r, opts, fun, sep), to: I.Algebra
  defdelegate to_doc(term, opts), to: I.Algebra

  #
  # Functional interface to "doc" records
  #

  #
  # Lifted from `Inspect.Algebra.is_doc/1`
  #
  @type t :: :doc_nil | :doc_line | doc_cons | doc_nest | doc_break | doc_group | binary

  #
  # Lifted from `Inspect.Algebra.is_doc/1`
  #
  @typep doc_cons :: {:doc_cons, t, t}
  defmacrop doc_cons(left, right) do
    quote do: {:doc_cons, unquote(left), unquote(right)}
  end

  #
  # Lifted from `Inspect.Algebra.is_doc/1`
  #
  @typep doc_nest :: {:doc_nest, t, non_neg_integer}
  defmacrop doc_nest(doc, indent) do
    quote do: {:doc_nest, unquote(doc), unquote(indent)}
  end

  #
  # Lifted from `Inspect.Algebra.is_doc/1`
  #
  @typep doc_break :: {:doc_break, binary}
  defmacrop doc_break(break) do
    quote do: {:doc_break, unquote(break)}
  end

  #
  # Lifted from `Inspect.Algebra.is_doc/1`
  #
  @typep doc_group :: {:doc_group, t}
  defmacrop doc_group(group) do
    quote do: {:doc_group, unquote(group)}
  end

  #
  # Lifted from `Inspect.Algebra.is_doc/1`
  #
  defmacrop is_doc(doc) do
    if Macro.Env.in_guard?(__CALLER__) do
      do_is_doc(doc)
    else
      var = quote do: doc
      quote do
        unquote(var) = unquote(doc)
        unquote(do_is_doc(var))
      end
    end
  end

  #
  # Lifted from `Inspect.Algebra.do_is_doc/1`
  #
  defp do_is_doc(doc) do
    quote do
      is_binary(unquote(doc)) or
      unquote(doc) in [:doc_nil, :doc_line] or
      (is_tuple(unquote(doc)) and
       elem(unquote(doc), 0) in [:doc_cons, :doc_nest, :doc_break, :doc_group])
    end
  end

  @doc ~S"""
  Formats a given document for a given width.

  Takes the maximum width and a document to print as its arguments
  and returns an IO data representation of the best layout for the
  document to fit in the given width.

  ## Examples

      iex> doc = glue("hello", " ", "world")
      iex> format(doc, 30) |> IO.iodata_to_binary()
      "hello world"
      iex> format(doc, 10) |> IO.iodata_to_binary()
      "hello\nworld"

  """
  @spec format(t, non_neg_integer | :infinity) :: iodata
  def format(doc, width) when is_doc(doc)
                         and (width == :infinity or width >= 0) do
    format(width, 0, [{0, default_mode(width), doc_group(doc)}])
  end


  defp default_mode(:infinity),
    do: :flat

  defp default_mode(_),
    do: :break


  # Record representing the document mode to be rendered: flat or broken
  @typep mode :: :flat | :break

  @spec fits?(integer, [{integer, mode, t}]) :: boolean
  defp fits?(limit, _) when limit < 0,
    do: false

  defp fits?(_, []),
    do: true

  defp fits?(_, [{_, _, :doc_line} | _]),
    do: true

  defp fits?(limit, [{_, _, :doc_nil} | t]),
    do: fits?(limit, t)

  defp fits?(limit, [{indent, m, doc_cons(x, y)} | t]),
    do: fits?(limit, [{indent, m, x} | [{indent, m, y} | t]])

  defp fits?(limit, [{indent, m, doc_nest(x, j)} | t]),
    do: fits?(limit, [{indent + j, m, x} | t])

  defp fits?(limit, [{indent, _, doc_group(x)} | t]),
    do: fits?(limit, [{indent, :flat, x} | t])

  defp fits?(limit, [{_, _, s} | t]) when is_binary(s),
    do: fits?((limit - byte_size(s)), t)

  defp fits?(limit, [{_, :flat, doc_break(s)} | t]),
    do: fits?((limit - byte_size(s)), t)

  defp fits?(_, [{_, :break, doc_break(_)} | _]),
    do: true


  @spec format(integer | :infinity, integer, [{integer, mode, t}]) :: [binary]
  defp format(_, _, []) do
    []
  end

  defp format(limit, _, [{indent, _, :doc_line} | t]) do
    [line_indent(indent) | format(limit, indent, t)]
  end

  defp format(limit, width, [{_, _, :doc_nil} | t]) do
    format(limit, width, t)
  end

  defp format(limit, width, [{indent, mode, doc_cons(x, y)} | t]) do
    docs = [{indent, mode, x} | [{indent, mode, y} | t]]
    format(limit, width, docs)
  end

  defp format(limit, width, [{indent, mode, doc_nest(x, j)} | t]) do
    docs = [{indent + j, mode, x} | t]
    format(limit, width, docs)
  end

  defp format(limit, width, [{indent, mode, doc_group(doc)} | t]) do
    docs = [{indent, mode, doc} | t]
    format(limit, width, docs)
  end

  defp format(limit, width, [{_, _, s} | t]) when is_binary(s) do
    new_width = width + byte_size(s)
    [s | format(limit, new_width, t)]
  end

  defp format(limit, width, [{_, :flat, doc_break(s)} | t]) do
    new_width = width + byte_size(s)
    [s | format(limit, new_width, t)]
  end

  defp format(limit, width, [{indent, :break, doc_break(s)} | t]) do
    new_width = width + byte_size(s)

    if limit == :infinity or fits?(limit - new_width, t) do
      [s | format(limit, new_width, t)]
    else
      [line_indent(indent) | format(limit, indent, t)]
    end
  end


  defp line_indent(0) do
    "\n"
  end

  defp line_indent(i) do
    "\n" <> :binary.copy(" ", i)
  end
end
