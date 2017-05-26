defmodule Exfmt.AlgebraTest do
  use ExUnit.Case, async: true
  doctest Exfmt.Algebra, import: true
  require Exfmt.Algebra
  import Exfmt.Algebra

  def fmt(doc, limit) do
    doc
    |> Exfmt.Algebra.format(limit)
    |> IO.iodata_to_binary()
    |> (&(&1 <> "\n")).()
  end

  describe "format/2" do
    test "empty / doc_nil" do
      assert empty() |> fmt(10) == """

      """
    end

    test "binary" do
      assert "Hello, world!" |> fmt(10) == """
      Hello, world!
      """
    end

    test "concat / doc_cons" do
      assert concat("a", "b") |> fmt(10) == """
      ab
      """
    end

    test "nest / doc_nest" do
      doc = nest(line("hello", "world"), 5)
      assert doc |> fmt(10) == """
      hello
           world
      """
    end

    test "group / doc_group" do
      doc = group(glue(glue(glue("a", "b"), "c"), "d"))
      assert doc |> fmt(7) == """
      a b c d
      """
      assert doc |> fmt(6) == """
      a
      b
      c
      d
      """
    end
  end
end
