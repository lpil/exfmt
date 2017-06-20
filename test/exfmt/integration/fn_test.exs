defmodule Exfmt.Integration.FnTest do
  use ExUnit.Case
  import Support.Integration

  test "captured functions" do
    "&inspect/1" ~> "&inspect/1\n"
    "&inspect(&1)" ~> "&inspect(&1)\n"
    "&merge(&2, &1)" ~> "&merge(&2, &1)\n"
  end

  test "captured infix operators" do
    "&(&2 + &1)" ~> "& &2 + &1\n"
    "(& &1.name)" ~> "& &1.name\n"
  end

  test "captured qualified function" do
    assert_format "&A.info/0\n"
  end

  test "calling captured functions" do
    "(&inspect/1).()" ~> "(&inspect/1).()\n"
    "(&(&1 <> x)).()" ~> "(& &1 <> x).()\n"
  end

  test "fn" do
    assert_format "fn-> :ok end\n"
    assert_format "fn(x) -> x end\n"
    """
    fn(x) -> y = x + x; y end
    """ ~> """
    fn(x) ->
      y = x + x
      y
    end
    """
  end

  test "multi-clause fn" do
    assert_format """
    fn
      {:ok, x} ->
        x

      x ->
        x
    end
    """
    assert_format """
    fn
      # One
      {:ok, x} ->
        x

      # Two
      x ->
        x
    end
    """
    assert_format """
    fn
      1, 2 ->
        2

      3, 4 ->
        4
    end
    """
  end

  test "multi-arity fun with when guard" do
    assert_format """
    fn(:ok, x) when is_map(x) -> x end
    """
  end

  @tag :skip
  test "multi-clause multi-arity fun with when guard" do
    assert_format """
    fn
      :ok, x when is_map(x) ->
        x
      _, _ ->
        :error
    end
    """
  end
end
