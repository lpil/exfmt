defmodule Exfmt.Integration.FnTest do
  use ExUnit.Case
  import Support.Integration

  test "captured functions" do
    "&inspect/1" ~> "&inspect/1\n"
    "&inspect(&1)" ~> "&inspect(&1)\n"
    "&merge(&2, &1)" ~> "&merge(&2, &1)\n"
  end

  test "captured +/2" do
    "&(&2 + &1)" ~> "& &2 + &1\n"
  end

  test "captured &1.prop" do
    "(& &1.name)" ~> "& &1.name()\n"
  end

  test "captured &&/2" do
    "&(&&/2)" ~> "& &&/2\n"
  end

  test "captured qualified function" do
    assert_format "&A.info/0\n"
  end

  test "calling captured functions" do
    "(&inspect/1).()" ~> "(&inspect/1).()\n"
    "(&(&1 <> x)).()" ~> "(& &1 <> x).()\n"
  end

  test "fn" do
    assert_format "fn -> :ok end\n"
    assert_format "fn x -> x end\n"
    """
    fn x -> y = x + x; y end
    """ ~> """
    fn x ->
      y = x + x
      y
    end
    """
  end

  test "fn in long function calls" do
    """
    Enum.find([1,2,3,4], fn num -> rem(num, 2) == 0 end)
    """ ~> """
    Enum.find [1, 2, 3, 4],
              fn num ->
                rem(num, 2) == 0
              end
    """

    """
    Logger.debug fn -> "Hey this is a long log message!" end
    """ ~> """
    Logger.debug fn ->
                   "Hey this is a long log message!"
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
    assert_format "& %{&1 | state: :ok}\n"
  end

  test "captured identity" do
    assert_format "& &1\n"
  end

  test "captured Access" do
    assert_format "& &1[:size]\n"
  end

  test "multi-arity fun with when guard" do
    assert_format """
    fn :ok, x when is_map(x) -> x end
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

  test "infix op with captured fn arg" do
    assert_format """
    (&List.flatten(&1)) == (&List.flatten/1)
    """
  end
end
