defmodule Exfmt.Integration.WhitespaceTest do
  use ExUnit.Case
  import Support.Integration

  test "one trailing newline" do
    assert_format "[1, 2, 3]\n"
  end

  test "multiple trailing newlines" do
    assert_format "[1, 2, 3]\n\n\n"
  end

  test "no trailing newline" do
    assert_format "[1, 2, 3]"
  end

  test "leading indent, one line of code" do
    assert_format "  [1, 2, 3]\n"
  end

  test "leading indent, multiple lines of code" do
    assert_format """
      fn(x) ->
        y = x + x
        y
      end
    """
  end

  test "multiple lines of code padded with blank lines" do
    assert_format """



          fn(x) ->
            y = x + x
            y
          end


    """
  end

  test "wraps if leading indent + code width > max width" do
    """
            [100000000, 100000000, 100000000]
    """ ~> """
            [100000000,
             100000000,
             100000000]
    """
  end
end
