defmodule ExfmtTest do
  use ExUnit.Case
  doctest Exfmt

  defmacro src ~> output do
    quote bind_quoted: binding() do
      assert Exfmt.format(src) == output
    end
  end

  test "positive ints" do
    "0" ~> "0"
    "1" ~> "1"
    "2" ~> "2"
  end

  test "negative numbers" do
    "-0" ~> "-0"
    "-1" ~> "-1"
    "-2" ~> "-2"
  end
end
