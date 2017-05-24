defmodule ExfmtTest do
  use ExUnit.Case
  doctest Exfmt

  defmacro src ~> expected do
    quote bind_quoted: binding() do
      assert Exfmt.format(src, 40) == expected
    end
  end

  test "ints" do
    "0" ~> "0\n"
    "1" ~> "1\n"
    "2" ~> "2\n"
    "-0" ~> "0\n"
    "-1" ~> "-1\n"
    "-2" ~> "-2\n"
  end

  test "floats" do
    "0.000" ~> "0.0\n"
    "1.111" ~> "1.111\n"
    "2.08" ~> "2.08\n"
    "-0.000" ~> "0.0\n"
    "-0.123" ~> "-0.123\n"
    "-1.123" ~> "-1.123\n"
    "-2.123" ~> "-2.123\n"
  end

  test "atoms" do
    ":ok" ~> ":ok\n"
    ":\"hello-world\"" ~> ":\"hello-world\"\n"
    ":\"[]\"" ~> ":\"[]\"\n"
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

  test "captured functions" do
    "inspect/1" ~> "inspect/1\n"
    "&inspect/1" ~> "&inspect/1\n"
    "&inspect(&1)" ~> "&inspect(&1)\n"
    "&merge(&2, &1)" ~> "&merge(&2, &1)\n"
    "&(&2 + &1)" ~> "& &2 + &1\n"
  end

  test "fn functions" do
    "fn -> :ok end" ~> "fn-> :ok end\n"
    "fn(x) -> x end" ~> "fn(x) -> x end\n"
    """
    fn(x) -> y = x + x; y end
    """ ~> """
    fn(x) ->
      y = x + x
      y
    end
    """
  end

  test "function calls" do
    "hello()" ~> "hello()\n"
    "reverse \"hi\"" ~> "reverse \"hi\"\n"
    "add 1, 2" ~> "add 1, 2\n"
    "add 1, 2, 3" ~> "add 1, 2, 3\n"
    """
    very_long_function_name_here :hello, :world
    """ ~> """
    very_long_function_name_here :hello,
                                 :world
    """
    """
    very_long_function_name_here([100, 200, 300])
    """ ~> """
    very_long_function_name_here [100, 200,
                                  300]
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
    "my_mod.get(0)" ~> "my_mod.get 0\n"
    "my_mod.get 0" ~> "my_mod.get 0\n"
    "String.length( my_string )" ~> "String.length my_string\n"
    ":lists.reverse my_list" ~> ":lists.reverse my_list\n"
  end

  test "calls with keyword args" do
    "hello(foo: 1)" ~> "hello foo: 1\n"
    "hello([foo: 1])" ~> "hello foo: 1\n"
    "hello([  foo:   1])" ~> "hello foo: 1\n"
  end

  test "Access protocol" do
    "keys[:name]" ~> "keys[:name]\n"
    "some_list[\n   :name\n]" ~> "some_list[:name]\n"
  end

  test "require" do
    "require Foo" ~> "require Foo\n"
    "require(Foo)" ~> "require Foo\n"
    "require    Foo" ~> "require Foo\n"
    "require Foo.Bar" ~> "require Foo.Bar\n"
    """
    require Really.Long.Module.Name, Another.Really.Long.Module.Name
    """ ~> """
    require Really.Long.Module.Name,
            Another.Really.Long.Module.Name
    """
  end

  test "import" do
    "import Foo" ~> "import Foo\n"
    "import(Foo)" ~> "import Foo\n"
    "import    Foo" ~> "import Foo\n"
    "import Foo.Bar" ~> "import Foo.Bar\n"
    """
    import Really.Long.Module.Name, Another.Really.Long.Module.Name
    """ ~> """
    import Really.Long.Module.Name,
           Another.Really.Long.Module.Name
    """
    """
    import Foo,
      only: [{:bar, 7}]
    """ ~>
    """
    import Foo, only: [bar: 7]
    """
  end

  test "alias" do
    "alias Foo" ~> "alias Foo\n"
    "alias(Foo)" ~> "alias Foo\n"
    "alias    Foo" ~> "alias Foo\n"
    "alias Foo.Bar" ~> "alias Foo.Bar\n"
    "alias String, as: S" ~> "alias String, as: S\n"
    "alias Element.{Storm,Earth,Fire}" ~> "alias Element.{Storm, Earth, Fire}\n"
    """
    alias Element.{Storm,Earth,Fire,Nature,Courage,Heart}
    """ ~> """
    alias Element.{Storm, Earth, Fire,
                   Nature, Courage, Heart}
    """
    """
    alias Really.Long.Module.Name.That.Does.Not.Fit.In.Width
    """ ~> """
    alias Really.Long.Module.Name.That.Does.Not.Fit.In.Width
    """
  end

  test "doctest" do
    "doctest Foo" ~> "doctest Foo\n"
  end

  test "defstruct" do
    "defstruct attrs" ~> "defstruct attrs\n"
    "defstruct []" ~> "defstruct []\n"
    "defstruct [:size, :age]" ~> "defstruct [:size, :age]\n"
    "defstruct [size: 1, age: 2]" ~> "defstruct size: 1, age: 2\n"
  end

  test "maths" do
    "1 + 2" ~> "1 + 2\n"
    "1 - 2" ~> "1 - 2\n"
    "1 * 2" ~> "1 * 2\n"
    "1 / 2" ~> "1 / 2\n"
    "1 * 2 + 3" ~> "1 * 2 + 3\n"
    "1 + 2 * 3" ~> "1 + 2 * 3\n"
    "(1 + 2) * 3" ~> "(1 + 2) * 3\n"
    "(1 - 2) * 3" ~> "(1 - 2) * 3\n"
    "1 / 2 + 3" ~> "1 / 2 + 3\n"
    "1 + 2 / 3" ~> "1 + 2 / 3\n"
    "(1 + 2) / 3" ~> "(1 + 2) / 3\n"
    "(1 - 2) / 3" ~> "(1 - 2) / 3\n"
    "1 * 2 / 3" ~> "1 * 2 / 3\n"
    "1 / 2 * 3" ~> "1 / 2 * 3\n"
    """
    something_really_really_really_really_long + 2
    """ ~> """
    something_really_really_really_really_long +
      2
    """
  end

  test "@spec" do
    "@spec bar() :: 1" ~> "@spec bar() :: 1\n"
    "@spec ok :: :ok" ~> "@spec ok :: :ok\n"
    """
    @spec run(String.t, [tern]) :: atom
    """ ~> """
    @spec run(String.t, [tern]) :: atom
    """
    # FIXME: Nesting correctly here is hard as we don't know
    # the string length of the args. We would need to indent
    # by this much to match the style used in the Elixir
    # compiler.
    """
    @spec run(String.t, [tern]) :: atom | String.t | :hello
    """ ~> """
    @spec run(String.t, [tern]) :: atom |
            String.t | :hello
    """
  end

  test "list patterns" do
    "[head1, head2|tail]" ~> "[head1, head2 | tail]\n"
  end

  test "use" do
    "use ExUnit.Case, async: true" ~> "use ExUnit.Case, async: true\n"
  end

  test "send" do
    "send my_pid, :hello" ~> "send my_pid, :hello\n"
  end

  test "magic variables" do
    "__MODULE__" ~> "__MODULE__\n"
    "__CALLER__" ~> "__CALLER__\n"
  end

  test "booleans" do
    "true" ~> "true\n"
    "false" ~> "false\n"
  end

  test "||" do
    "true || true" ~> "true || true\n"
  end

  test "&&" do
    "true && true" ~> "true && true\n"
  end

  test "or" do
    "true or true" ~> "true or true\n"
  end

  test "and" do
    "true and true" ~> "true and true\n"
  end

  test "in" do
    "x in [1, 2]" ~> "x in [1, 2]\n"
  end

  test "~>" do
    "x ~> [1, 2]" ~> "x ~> [1, 2]\n"
  end

  test ">>>" do
    "x >>> [1, 2]" ~> "x >>> [1, 2]\n"
  end

  test "<>" do
    "x <> y" ~> "x <> y\n"
  end

  test "pipes |>" do
    """
    1 |> double() |> Number.triple()
    """ ~> """
    1
    |> double()
    |> Number.triple
    """
  end

  test "blocks" do
    """
    1 + 1
    """ ~>
    """
    1 + 1
    """
    """
    1 + 1
    2 / 3
    """ ~>
    """
    1 + 1
    2 / 3
    """
    """
    run(1)
    run(2)
    run(3)
    """ ~>
    """
    run 1
    run 2
    run 3
    """
  end

  test "do end blocks" do
    """
    test "hello" do
      :ok
    end
    """ ~>
    """
    test "hello" do
      :ok
    end
    """
    """
    if x do
      :ok
    else
      :ok
    end
    """ ~>
    """
    if x do
      :ok
    else
      :ok
    end
    """
  end

  test "calls at top level of do block" do
    """
    defmodule FooMod do
      use(Foo)
      import(Foo)
      require(Foo)
      alias(Foo)
      doctest(Foo)
      save use(Foo)
      save import(Foo)
      save require(Foo)
      save alias(Foo)
      save doctest(Foo)
    end
    """ ~> """
    defmodule FooMod do
      use Foo
      import Foo
      require Foo
      alias Foo
      doctest Foo
      save use(Foo)
      save import(Foo)
      save require(Foo)
      save alias(Foo)
      save doctest(Foo)
    end
    """
  end

  test "case" do
    """
    case number do
      1 ->
        :one
      2 -> :two
    end
    """ ~> """
    case number do
      1 ->
        :one

      2 ->
        :two
    end
    """
    """
    case number do
      x when is_integer(x) ->
        :int
      _ -> nil
    end
    """ ~> """
    case number do
      x when is_integer(x) ->
        :int

      _ ->
        nil
    end
    """
  end
end
