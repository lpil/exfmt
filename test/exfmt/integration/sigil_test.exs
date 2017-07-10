defmodule Exfmt.Integration.SigilTest do
  use ExUnit.Case
  import Support.Integration

  test "r sigils" do
    assert_format "~r/hello/"
    assert_format "~r/hello/ugi"
    assert_format "~R/hello/"
    assert_format "~R/hello/ugi"
    "~r(hello)" ~> "~r/hello/"
    "~r[hello]" ~> "~r/hello/"
    "~r{hello}" ~> "~r/hello/"
    ~S"~r/\//" ~> "~r(/)"
  end

  test "r sigil 2" do
    ~S"~r/\/()/" ~> ~S"~r(/(\))" <> ""
  end

  test "s sigils" do
    assert_format ~s[~s(hello)]
    ~S(~s"hello") ~> ~s[~s(hello)]
    ~S(~s/hello/ugi) ~> ~s[~s(hello)ugi]
    ~S(~S"hello") ~> ~s[~S(hello)]
    ~S(~S/hello/ugi) ~> ~s[~S(hello)ugi]
    ~S(~s[hello]) ~> ~s[~s(hello)]
    ~S(~s{hello}) ~> ~s[~s(hello)]
    ~S[~s"()"] ~> ~s{~s[()]}
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

  test "sigil with interp first" do
    assert_format ~S"""
    ~r/#{1} 2/
    """
  end

  test "sigil containing exciting unicode" do
    assert_format """
    ~S(ø)
    """
  end

  test "sigil containing new close char that will need to be escaped" do
    ~S"""
    ~R" \( \) / "
    """ ~> ~S"""
    ~R( \( \\\) / )
    """
  end

  test "sigil defintions" do
    assert_format """
    defmacro sigil_T(date, modifiers)
    """
    assert_format """
    def sigil_u(content, modifiers)
    """
  end

  test "unsugared sigil defintions" do
    assert_format """
    sigil_T("123", [])
    """
    assert_format """
    sigil_u("456", [])
    """
  end
end
