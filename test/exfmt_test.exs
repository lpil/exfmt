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

  test "keyword lists" do
    "[]" ~> "[]\n"
    "[a: 1]" ~> "[a: 1]\n"
    "[ b:  {} ]" ~> "[b: {}]\n"
    "[a: 1, b: 2]" ~> "[a: 1, b: 2]\n"
    "[{:a, 1}]" ~> "[a: 1]\n"
  end

  test "charlists" do
    "''" ~> "[]\n"
    "'a'" ~> "[97]\n" # TODO: Hmm...
  end

  test "r sigils" do
    "~r/hello/" ~> "~r/hello/\n"
    "~r/hello/ugi" ~> "~r/hello/ugi\n"
    "~R/hello/" ~> "~R/hello/\n"
    "~R/hello/ugi" ~> "~R/hello/ugi\n"
    "~r(hello)" ~> "~r/hello/\n"
    "~r[hello]" ~> "~r/hello/\n"
    "~r{hello}" ~> "~r/hello/\n"
    ~S"~r/\//" ~> "~r(/)\n"
    ~S"~r/\/)/" ~> "~r(/\))\n"
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

  test "variables" do
    "some_var" ~> "some_var\n"
    "_another_var" ~> "_another_var\n"
    "thing1" ~> "thing1\n"
  end

  test "module attributes" do
    "@size" ~> "@size\n"
    "@foo 1" ~> "@foo 1\n"
    "@tag :skip" ~> "@tag :skip\n"
    """
    @sizes [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]
    """ ~> """
    @sizes [1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
            11, 12, 13, 14, 15, 16]
    """
  end

  test "qualified calls" do
    "Process.get()" ~> "Process.get\n"
    "Process.get" ~> "Process.get\n"
    "my_mod.get" ~> "my_mod.get\n"
    "my_mod.get(0)" ~> "my_mod.get(0)\n"
    "String.length( my_string )" ~> "String.length(my_string)\n"
  end
end
