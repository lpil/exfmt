defmodule CallTest do
  use ExUnit.Case, async: true
  import Support.Integration, only: [~>: 2]

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
    very_long_function_name_here [100,
                                  200,
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
    alias Element.{Storm,
                   Earth,
                   Fire,
                   Nature,
                   Courage,
                   Heart}
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

  test "use" do
    "use ExUnit.Case, async: true" ~> "use ExUnit.Case, async: true\n"
  end

  test "send" do
    "send my_pid, :hello" ~> "send my_pid, :hello\n"
  end
end
