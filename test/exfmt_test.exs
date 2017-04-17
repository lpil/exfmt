defmodule ExfmtTest do
  use ExUnit.Case
  doctest Exfmt

  defmacro src ~> output do
    quote bind_quoted: binding() do
      assert Exfmt.format(src, 40) == output
    end
  end

  test "positive ints" do
    "0" ~> "0\n"
    "1" ~> "1\n"
    "2" ~> "2\n"
  end

  test "negative numbers" do
    "-0" ~> "0\n"
    "-1" ~> "-1\n"
    "-2" ~> "-2\n"
  end

  test "atoms" do
    ":ok" ~> ":ok\n"
    ":\"hello-world\"" ~> ":\"hello-world\"\n"
    ":_" ~> ":_\n"
  end

  test "aliases" do
    "String" ~> "String\n"
    "My.String" ~> "My.String\n"
    "App.Web.Controller" ~> "App.Web.Controller\n"
  end

  test "strings" do
    ~s("") ~> ~s(""\n)
    ~s(" ") ~> ~s(" "\n)
    ~s("\n") ~> ~s("\\n"\n)
    ~s("""\nhello\n""") ~> ~s("hello\\n"\n) # TODO: Use heredocs
  end

  test "maps" do
    "%{}" ~> "%{}\n"
    "%{a: 1}" ~> "%{a: 1}\n"
    "%{:a => 1}" ~> "%{a: 1}\n"
    "%{1 => 1}" ~> "%{1 => 1}\n"
  end

  test "lists" do
    "[ ]" ~> "[]\n"
    """
    [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19]
    """ ~> """
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
     12, 13, 14, 15, 16, 17, 18, 19]
    """
  end

  test "tuples" do
    "{}" ~> "{}\n"
    "{1}" ~> "{1}\n"
    "{1,2}" ~> "{1, 2}\n"
    "{1,2,3}" ~> "{1, 2, 3}\n"
  end

  test "functions" do
    "inspect/1" ~> "inspect/1\n"
  end

  test "function calls" do
    "hello()" ~> "hello()\n"
    "reverse(\"hi\")" ~> "reverse(\"hi\")\n"
    "add(1, 2)" ~> "add(1, 2)\n"
    "add(1, 2, 3)" ~> "add(1, 2, 3)\n"
    """
    very_long_function_name_here(:hello, :world)
    """ ~> """
    very_long_function_name_here(:hello,
                                 :world)
    """
    """
    very_long_function_name_here([100, 200, 300])
    """ ~> """
    very_long_function_name_here([100, 200,
                                  300])
    """
  end

  test "anon function calls" do
    "hello.()" ~> "hello.()\n"
    "reverse.(\"hi\")" ~> "reverse.(\"hi\")\n"
    "add.(1, 2)" ~> "add.(1, 2)\n"
    "add.(1, 2, 3)" ~> "add.(1, 2, 3)\n"
    """
    very_long_function_name_here.(:hello, :world)
    """ ~> """
    very_long_function_name_here.(:hello,
                                  :world)
    """
  end
end
