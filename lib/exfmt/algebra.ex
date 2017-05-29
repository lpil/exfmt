defmodule Exfmt.Algebra do
  @moduledoc """
  A set of functions for creating and manipulating algebra
  documents.

  This module implements the functionality described in
  ["Strictly Pretty" (2000) by Christian Lindig][0], with a few
  extensions detailed below.

  [0]: http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.34.2200

  It serves an alternative printer to the one defined in
  `Inspect.Algebra`, which is part of the Elixir standard library
  but does not entirely conform to the algorithm described by Christian
  Lindig in a way that makes it unsuitable for use in ExFmt.


  ## Extensions

  `wide/1` has been added to support printing of forms that span to the
  end of the line, such as comments.

  """

  alias Inspect, as: I
  require I.Algebra

  #
  # Functional interface to "doc" records
  #

  #
  # Lifted from `Inspect.Algebra.is_doc/1`
  #
  @type t
    :: :doc_nil
    | :doc_line
    | doc_cons
    | doc_nest
    | doc_break
    | doc_group
    | doc_wide
    | binary

  @typep doc_wide :: {:doc_wide, t}
  defmacrop doc_wide(doc) do
    quote do: {:doc_wide, unquote(doc)}
  end

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
  # Lifted from `Inspect.Algebra.do_is_doc/1`, and then
  # extended with the new Algebra.
  #
  defp do_is_doc(doc) do
    quote do
      is_binary(unquote(doc)) or
      unquote(doc) in [:doc_nil, :doc_line] or
      (is_tuple(unquote(doc)) and
       elem(unquote(doc), 0) in
        [:doc_cons, :doc_nest, :doc_break, :doc_group, :doc_wide])
    end
  end


  #
  # Public interface to algebra
  #

  defdelegate empty(), to: I.Algebra
  defdelegate break(), to: I.Algebra
  defdelegate break(doc), to: I.Algebra
  defdelegate fold_doc(docs, fun), to: I.Algebra
  defdelegate group(doc), to: I.Algebra
  defdelegate line(doc1, doc2), to: I.Algebra
  defdelegate nest(doc, level), to: I.Algebra
  defdelegate space(doc1, doc2), to: I.Algebra
  defdelegate surround(left, doc, right), to: I.Algebra
  defdelegate surround_many(l, docs, r, opts, fun), to: I.Algebra
  defdelegate surround_many(l, docs, r, opts, fun, sep), to: I.Algebra
  defdelegate to_doc(term, opts), to: I.Algebra


  @doc ~S"""
  The wide algebra will never fit, it always causes a break.
  We use this to represent comments as they span to the end
  of the line, no matter what the line limit is.

  ## Examples

      iex> doc = glue(wide("hello"), "world")
      ...> format(doc, 80)
      ["hello", "\n", "world"]

  """
  @spec wide(t) :: t
  def wide(doc) do
    doc_wide(doc)
  end


  @doc ~S"""
  Concatenates two document entities returning a new document.

  ## Examples

      iex> doc = concat("hello", "world")
      ...> format(doc, 80)
      ["hello", "world"]

  """
  @spec concat(t, t) :: t
  def concat(doc1, doc2) when is_doc(doc1) and is_doc(doc2) do
    doc_cons(doc1, doc2)
  end


  @doc ~S"""
  Concatenates a list of documents returning a new document.

  ## Examples

      iex> doc = concat(["a", "b", "c"])
      ...> format(doc, 80)
      ["a", "b", "c"]

  """
  @spec concat([t]) :: t
  def concat(docs) when is_list(docs) do
    fold_doc(docs, &concat(&1, &2))
  end


  @doc ~S"""
  Glues two documents together inserting `" "` as a break between them.

  This means the two documents will be separated by `" "` in case they
  fit in the same line. Otherwise a line break is used.

  ## Examples

      iex> doc = glue("hello", "world")
      ...> format(doc, 80)
      ["hello", " ", "world"]

  """
  @spec glue(t, t) :: t
  def glue(doc1, doc2), do: concat(doc1, concat(break(), doc2))

  @doc ~S"""
  Glues two documents (`doc1` and `doc2`) together inserting the given
  break `break_string` between them.

  For more information on how the break is inserted, see `break/1`.

  ## Examples

      iex> doc = glue("hello", "\t", "world")
      ...> format(doc, 80)
      ["hello", "\t", "world"]

  """
  @spec glue(t, binary, t) :: t
  def glue(doc1, break_string, doc2) when is_binary(break_string),
    do: concat(doc1, concat(break(break_string), doc2))

  #
  # Manipulation functions
  #

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


  defp default_mode(:infinity) do
    :flat
  end

  defp default_mode(_) do
    :break
  end


  # Record representing the document mode to be rendered: flat or broken
  @typep mode :: :flat | :break

  @spec fits?(integer, [{integer, mode, t}]) :: boolean

  defp fits?(limit, _) when limit < 0 do
    false
  end

  defp fits?(_, []) do
    true
  end

  defp fits?(_, [{_, _, :doc_line} | _]) do
    true
  end

  defp fits?(limit, [{_, _, :doc_nil} | t]) do
    fits?(limit, t)
  end

  defp fits?(limit, [{indent, m, doc_cons(x, y)} | t]) do
    fits?(limit, [{indent, m, x} | [{indent, m, y} | t]])
  end

  defp fits?(limit, [{indent, m, doc_nest(x, i)} | t]) do
    fits?(limit, [{indent + i, m, x} | t])
  end

  defp fits?(limit, [{_, _, s} | t]) when is_binary(s) do
    fits?((limit - byte_size(s)), t)
  end

  defp fits?(_, [{_, _, doc_wide(_)} | _rest]) do
    false
  end

  defp fits?(limit, [{_, :flat, doc_break(s)} | t]) do
    fits?((limit - byte_size(s)), t)
  end

  defp fits?(_, [{_, :break, doc_break(_)} | _]) do
    true
  end

  defp fits?(limit, [{indent, _, doc_group(x)} | t]) do
    fits?(limit, [{indent, :flat, x} | t])
  end


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

  defp format(limit, width, [{indent, mode, doc_nest(x, extra_indent)} | t]) do
    docs = [{indent + extra_indent, mode, x} | t]
    format(limit, width, docs)
  end

  defp format(limit, _, [{_, _, doc_wide(x)} | t]) do
    [x | format(limit, limit + 1, t)]
  end

  defp format(limit, width, [{_, _, s} | t]) when is_binary(s) do
    new_width = width + byte_size(s)
    [s | format(limit, new_width, t)]
  end

  defp format(limit, width, [{_, :flat, doc_break(s)} | t]) do
    new_width = width + byte_size(s)
    [s | format(limit, new_width, t)]
  end

  defp format(limit, _width, [{indent, :break, doc_break(_s)} | t]) do
    [line_indent(indent) | format(limit, indent, t)]
  end

  defp format(limit, width, [{indent, _mode, doc_group(doc)} | t]) do
    flat_docs = [{indent, :flat, doc} | t]
    if fits?(limit - width, flat_docs) do
      format(limit, width, flat_docs)
    else
      break_docs = [{indent, :break, doc} | t]
      format(limit, width, break_docs)
    end
  end


  defp line_indent(0) do
    "\n"
  end

  defp line_indent(i) do
    "\n" <> :binary.copy(" ", i)
  end
end
