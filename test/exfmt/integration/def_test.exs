defmodule Exfmt.Integration.DefTest do
  use ExUnit.Case
  import Support.Integration

  test "def with guard" do
    assert_format """
    def one?(x) when x in [:one, "one"] do
      true
    end
    """
  end

  test "def with long guard" do
    """
    def one?(x) when x in [:one, "one", 1, "1"] do
      true
    end
    """ ~> """
    def one?(x)
        when x in [:one, "one", 1, "1"] do
      true
    end
    """
  end

  test "def with zero arity" do
    """
    def one do
      1
    end
    """ ~> """
    def one() do
      1
    end
    """
  end

  test "defp with zero arity" do
    """
    defp one do
      1
    end
    """ ~> """
    defp one() do
      1
    end
    """
  end

  test "defmacro with zero arity" do
    """
    defmacro one do
      1
    end
    """ ~> """
    defmacro one() do
      1
    end
    """
  end

  test "defmacrop with zero arity" do
    """
    defmacrop one do
      1
    end
    """ ~> """
    defmacrop one() do
      1
    end
    """
  end

  test "defdelegate with zero arity" do
    """
    defdelegate one do
      1
    end
    """ ~> """
    defdelegate one() do
      1
    end
    """
  end

  test "def spacing" do
    assert_format """
    def one(1) do
      1
    end

    def one(2) do
      2
    end


    def two(1) do
      1
    end

    def two(2) do
      2
    end
    """
  end

  test "def spacing with comments" do
    assert_format """
    # One comment
    def one() do
      2
    end


    def two() do
      1
    end
    """
  end

  test "def with unquote name" do
    assert_format ~S"""
    defmacrop unquote(name)(arg) do
      arg
    end
    """
  end

  test "negated guard" do
    assert_format """
    def run(x) when not is_binary(x) do
      x
    end
    """
  end
end
