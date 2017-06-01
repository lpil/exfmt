defmodule Exfmt.Integration.StringTest do
  use ExUnit.Case, async: true
  import Support.Integration, only: [~>: 2]

  test "strings" do
    ~s("") ~> ~s(""\n)
    ~s(" ") ~> ~s(" "\n)
    ~s("\n") ~> ~s("\\n"\n)
    ~s("""\nhello\n""") ~> ~s("hello\\n"\n) # TODO: Use heredocs
  end

  test "string interpolation" do
    ~S("#{1}") ~> ~S("#{1}") <> "\n"
    ~S("0 #{1}") ~> ~S("0 #{1}") <> "\n"
    ~S("0 #{1} 2 #{3}#{4}") ~> ~S("0 #{1} 2 #{3}#{4}") <> "\n"
  end
end
