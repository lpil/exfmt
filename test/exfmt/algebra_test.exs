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
      assert fmt(empty(), 10) == """

      """
    end

    test "binary" do
      assert fmt("Hello, world!", 10) == """
      Hello, world!
      """
    end

    test "concat / doc_cons" do
      assert fmt(concat("a", "b"), 10) == """
      ab
      """
    end

    test "nest / doc_nest" do
      doc = nest(line("hello", "world"), 5)
      assert fmt(doc, 10) == """
      hello
           world
      """
    end

    test "group / doc_group" do
      doc = group(glue(glue(glue("a", "b"), "c"), "d"))
      assert fmt(doc, 7) == """
      a b c d
      """
      assert fmt(doc, 6) == """
      a
      b
      c
      d
      """
    end

    test "wide / doc_wide" do
      doc = glue("a", glue(wide("b"), "c"))
      assert fmt(doc, 1000) == """
      a
      b
      c
      """
    end

    test "line / doc_line" do
      doc = nest(line("a", "b"), 2)
      assert fmt(doc, 40) == "a\n  b\n"
    end
  end
end
