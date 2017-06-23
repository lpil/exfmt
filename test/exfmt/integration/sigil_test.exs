defmodule Exfmt.Integration.SigilTest do
  use ExUnit.Case
  import Support.Integration

  test "r sigils" do
    assert_format "~r/hello/\n"
    assert_format "~r/hello/ugi\n"
    assert_format "~R/hello/\n"
    assert_format "~R/hello/ugi\n"
    "~r(hello)" ~> "~r/hello/\n"
    "~r[hello]" ~> "~r/hello/\n"
    "~r{hello}" ~> "~r/hello/\n"
    ~S"~r/\//" ~> "~r(/)\n"
    ~S"~r/\/)/" ~> ~S"~r(/\))" <> "\n"
  end

  test "s sigils" do
    assert_format ~s[~s(hello)\n]
    ~S(~s"hello") ~> ~s[~s(hello)\n]
    ~S(~s/hello/ugi) ~> ~s[~s(hello)ugi\n]
    ~S(~S"hello") ~> ~s[~S(hello)\n]
    ~S(~S/hello/ugi) ~> ~s[~S(hello)ugi\n]
    ~S(~s[hello]) ~> ~s[~s(hello)\n]
    ~S(~s{hello}) ~> ~s[~s(hello)\n]
    ~S[~s"()"] ~> ~s{~s[()]\n}
  end

  test "multi-line sigils" do
   assert_format """
    ~w(one two three four,
       let's go, to K mart!)a
    """
  end

  test "sigil with interp" do
    assert_format ~S"""
    ~s(1 #{2} 3)
    """
  end
end
