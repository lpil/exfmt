defmodule Exfmt.Integration.SigilTest do
  use ExUnit.Case
  import Support.Integration, only: [~>: 2]

  test "r sigils" do
    "~r/hello/" ~> "~r/hello/\n"
    "~r/hello/ugi" ~> "~r/hello/ugi\n"
    "~R/hello/" ~> "~R/hello/\n"
    "~R/hello/ugi" ~> "~R/hello/ugi\n"
    "~r(hello)" ~> "~r/hello/\n"
    "~r[hello]" ~> "~r/hello/\n"
    "~r{hello}" ~> "~r/hello/\n"
    ~S"~r/\//" ~> "~r(/)\n"
    ~S"~r/\/)/" ~> ~S"~r(/\))" <> "\n"
  end

  test "s sigils" do
    ~S(~s"hello") ~> ~s[~s(hello)\n]
    ~S(~s/hello/ugi) ~> ~s[~s(hello)ugi\n]
    ~S(~S"hello") ~> ~s[~S(hello)\n]
    ~S(~S/hello/ugi) ~> ~s[~S(hello)ugi\n]
    ~S(~s[hello]) ~> ~s[~s(hello)\n]
    ~S(~s{hello}) ~> ~s[~s(hello)\n]
    ~S[~s(hello)] ~> ~s[~s(hello)\n]
    ~S[~s"()"] ~> ~s{~s[()]\n}
  end

  test "multi-line sigils" do
    """
    ~w(one two three four,
       let's go, to K mart!)a
    """ ~>
    """
    ~w(one two three four,
       let's go, to K mart!)a
    """
  end
end
