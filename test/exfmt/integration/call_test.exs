defmodule Exfmt.Integration.CallTest do
  use ExUnit.Case, async: true
  import Support.Integration

  test "function calls" do
    assert_format "hello()\n"
    assert_format "reverse \"hi\"\n"
    assert_format "add 1, 2\n"
    assert_format "add 1, 2, 3\n"
    """
    very_long_function_name_here :hello, :world
    """ ~> """
    very_long_function_name_here :hello,
                                 :world
    """
    """
    very_long_function_name_here([100, 200, 300])
    """ ~> """
    very_long_function_name_here [
                                   100,
                                   200,
                                   300,
                                 ]
    """
  end

  test "anon function calls" do
    assert_format "hello.()\n"
    assert_format "reverse.(\"hi\")\n"
    assert_format "add.(1, 2)\n"
    assert_format "add.(1, 2, 3)\n"
    """
    very_long_function_name_here.(:hello, :world)
    """ ~> """
    very_long_function_name_here.(:hello,
                                  :world)
    """
    """
    very_long_function_name_here.(1, 2, 3, 4)
    """ ~> """
    very_long_function_name_here.(1,
                                  2,
                                  3,
                                  4)
    """
  end

  test "qualified calls" do
    "Process.get()" ~> "Process.get\n"
    assert_format "Process.get\n"
    assert_format "my_mod.get\n"
    "my_mod.get(0)" ~> "my_mod.get 0\n"
    assert_format "my_mod.get 0\n"
    "String.length( my_string )" ~> "String.length my_string\n"
    assert_format ":lists.reverse my_list\n"
  end

  test "calls with keyword args" do
    "hello(foo: 1)" ~> "hello foo: 1\n"
    "hello([foo: 1])" ~> "hello foo: 1\n"
    "hello([  foo:   1])" ~> "hello foo: 1\n"
  end

  test "require" do
    assert_format "require Foo\n"
    "require(Foo)" ~> "require Foo\n"
    "require    Foo" ~> "require Foo\n"
    assert_format "require Foo.Bar\n"
    """
    require Really.Long.Module.Name, Another.Really.Long.Module.Name
    """ ~> """
    require Really.Long.Module.Name,
            Another.Really.Long.Module.Name
    """
  end

  test "import" do
    assert_format "import Foo\n"
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
    assert_format "alias Foo\n"
    "alias(Foo)" ~> "alias Foo\n"
    "alias    Foo" ~> "alias Foo\n"
    assert_format "alias Foo.Bar\n"
    assert_format "alias String, as: S\n"
    "alias Element.{Storm,Earth,Fire}" ~> "alias Element.{Storm, Earth, Fire}\n"
    """
    alias Element.{Storm,Earth,Fire,Nature,Courage,Heart}
    """ ~> """
    alias Element.{Storm,
                   Earth,
                   Fire,
                   Nature,
                   Courage,
                   Heart}
    """
    assert_format "alias Really.Long.Module.Name.That.Does.Not.Fit.In.Width\n"
  end

  test "doctest" do
    assert_format "doctest Foo\n"
  end

  test "defstruct" do
    assert_format "defstruct attrs\n"
    assert_format "defstruct []\n"
    assert_format "defstruct [:size, :age]\n"
    "defstruct [size: 1, age: 2]" ~> "defstruct size: 1, age: 2\n"
  end

  test "use" do
    assert_format "use ExUnit.Case, async: true\n"
  end

  test "send" do
    assert_format "send my_pid, :hello\n"
  end

  test "call qualified by atom from another call" do
    assert_format "Mix.shell.info :ok\n"
  end

  test "call with keyword list not as last arg" do
    assert_format "print_tree [normal: app], opts\n"
  end

  test "unquoted function name call" do
    assert_format "unquote(callback).()\n"
  end

  test "call with arg with do block" do
    assert_format """
    write_beam(defmodule SampleDocs do
                 :ok
               end)
    """
  end

  test "calls with funs from macros" do
    assert_format """
    name(:name)(1)
    """
  end
end
