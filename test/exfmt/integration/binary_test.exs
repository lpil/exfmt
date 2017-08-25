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
    ~s("\n") ~> ~s("\\n"\n)
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

  test "charlist interpolation" do
    assert_format ~S"""
    '1 #{2} 3'
    """
  end

  test "empty binary" do
    assert_format "<<>>\n"
  end

  test "binaries with content" do
    assert_format "<<200>>\n"
    assert_format "<<1, 2, 3, 4>>\n"
    assert_format """
    <<100,
      200,
      300,
      400,
      500,
      600,
      700,
      800>>
    """
  end

  test "binaries with sized content" do
    assert_format "<<1::16>>\n"
    assert_format "<<1::8 * 4>>\n"
    assert_format """
    <<690::bits - size(8 - 4) - unit(1),
      65>>
    """
  end

  test "nested binaries" do
    assert_format "<<(<<65>>), 65>>\n"
    assert_format "<<65, (<<65>>)>>\n"
  end

  test "binary type" do
    assert_format "@my_bin foo :: <<_::8, _::_ * 4>>\n"
  end

  test "bit for comprehension" do
    assert_format """
    for <<(a :: 4 <- <<1, 2>>)>> do
      a
    end
    """
  end

  test "binary with only string content" do
    assert_format """
    <<"f", "oo">>
    """
  end

  test "strings with interpolation and a quote" do
    assert_format ~S"""
    " \" #{name}"
    """
  end

  test "strings with interpolation and escaped characters" do
    assert_format ~S"""
    "Error: Not enough memory to read file:\n   #{path}"
    """
  end

  test "empty heredoc" do
    assert_format ~s("""\n"""\n)
  end

  test "1 line heredoc" do
    assert_format ~s("""\none\n"""\n)
  end

  test "2 line heredoc" do
    assert_format ~s("""\none\ntwo\n"""\n)
  end

  test "heredoc with preceeding spaces" do
    assert_format ~s("""\none\n  two\n"""\n)
  end

  @tag :skip
  test "heredoc with scaped slash" do
    assert_format ~S("""
Hi \\ hello
"""
)
  end

  @tag :skip
  test "heredoc with scaped slash on own line" do
    assert_format ~S("""
\\
"""
)
  end
end
