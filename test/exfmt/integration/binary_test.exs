defmodule Exfmt.Integration.BinaryTest do
  use ExUnit.Case, async: true
  import Support.Integration

  test "strings" do
    assert_format """
    ""
    """
    assert_format """
    " "
    """
    # TODO: Use heredocs
    ~s("\n") ~> ~s("\\n"\n)
    ~s("""\nhello\n""") ~> ~s("hello\\n"\n)
  end

  test "string interpolation" do
    assert_format ~S"""
    "#{1}"
    """
    assert_format ~S"""
    "0 #{1}"
    """
    assert_format ~S"""
    "0 #{1} 2 #{3}#{4}"
    """
  end
end
