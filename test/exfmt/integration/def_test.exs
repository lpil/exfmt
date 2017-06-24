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
    def one do
      2
    end


    def two do
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
end
