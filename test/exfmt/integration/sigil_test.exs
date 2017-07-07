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
    ~S"~r/\/()/" ~> ~S"~r(/(\))" <> "\n"
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
  #
  # TODO: Work out what is suppsed to happen here.
  # I can't work out a way to render this in a fashion
  # that makes the compiler happy.
  # I'm wondering if there is a bug in the parser. There
  # seems to be a bug in the Inspect protocol.
  # https://github.com/elixir-lang/elixir/issues/6255
  #
  @tag :skip
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
