defmodule ExfmtTest do
  use ExUnit.Case, async: true
  doctest Exfmt, import: true

  describe "format/2" do
    test "formats valid source code" do
      assert Exfmt.format("[1,2,3]") == {:ok, "[1, 2, 3]\n"}
    end

    test "returns error on invalid syntax" do
      message = "syntax error before: ','"
      error = Exfmt.format(",")
      assert %Exfmt.SyntaxError{line: 1, message: message} == error
    end
  end

  describe "format!/2" do
    test "formats valid source code" do
      assert Exfmt.format!("[1,2,3]") == "[1, 2, 3]\n"
    end

    test "throws on invalid syntax" do
      message = "syntax error before: ','"
      error = catch_error(Exfmt.format!(","))
      assert %Exfmt.SyntaxError{line: 1, message: message} == error
    end
  end
end
