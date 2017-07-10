defmodule Exfmt.Integration.FnTest do
  use ExUnit.Case
  import Support.Integration

  test "captured functions" do
    assert_format "&inspect/1"
    assert_format "&inspect(&1)"
    assert_format "&merge(&2, &1)"
  end

  test "captured infix operators" do
    "&(&2 + &1)" ~> "& &2 + &1"
    "(& &1.name)" ~> "& &1.name"
  end

  test "captured qualified function" do
    assert_format "&A.info/0"
  end

  test "calling captured functions" do
    assert_format "(&inspect/1).()"
    "(&(&1 <> x)).()" ~> "(& &1 <> x).()"
  end

  test "fn" do
    assert_format "fn-> :ok end"
    assert_format "fn(x) -> x end"
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

  test "captured map update fn" do
    assert_format "& %{&1 | state: :ok}"
  end

  test "captured identity" do
    assert_format "& &1"
  end

  test "captured Access" do
    assert_format "& &1[:size]"
  end

  test "multi-arity fun with when guard" do
    assert_format """
    fn(:ok, x) when is_map(x) -> x end
    """
  end

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
