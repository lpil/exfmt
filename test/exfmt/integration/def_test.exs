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
    assert_format """
    defp valid?(left, doc, right)
         when is_doc(left)
         when is_doc(doc)
         when is_doc(right) do
      :ok
    end
    """
    assert_format """
    defp valid_operation?(op, args, ref)
         when is_atom(op) and
              not op in @unary_ops and
              not op in @binary_ops
         when is_map(args) and
              map_size(map) > 2
         when is_list(ref) or
              not is_nil(level) or
              is_float(args) or
              is_integer(ref) or
              rem(ref, 2) == 0 do
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

  test "negated guard" do
    assert_format """
    def run(x) when not is_binary(x) do
      x
    end
    """
  end

  test "def with many arguments" do
    assert_format """
    def generate_buffer(
          start_expr,
          start_line,
          mark,
          chars,
          buffer
        ) do
      :ok
    end
    """
  end

  test "def with many arguments and complex guard" do
    assert_format """
    def generate_buffer(
          start_expr,
          start_line,
          mark,
          chars,
          buffer
        )
        when is_atom(mark) and
             not op in @unary_ops
        when is_atom(mark) do
      :ok
    end
    """
  end
end
