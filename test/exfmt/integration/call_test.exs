defmodule Exfmt.Integration.CallTest do
  use ExUnit.Case, async: true
  import Support.Integration

  test "function calls" do
    assert_format "hello()"
    assert_format "reverse \"hi\""
    assert_format "add 1, 2"
    assert_format "add 1, 2, 3"
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
    assert_format "hello.()"
    assert_format "reverse.(\"hi\")"
    assert_format "add.(1, 2)"
    assert_format "add.(1, 2, 3)"
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
    "Process.get()" ~> "Process.get"
    assert_format "Process.get"
    assert_format "my_mod.get"
    "my_mod.get(0)" ~> "my_mod.get 0"
    assert_format "my_mod.get 0"
    "String.length( my_string )" ~> "String.length my_string"
    assert_format ":lists.reverse my_list"
  end

  test "calls with keyword args" do
    "hello(foo: 1)" ~> "hello foo: 1"
    "hello([foo: 1])" ~> "hello foo: 1"
    "hello([  foo:   1])" ~> "hello foo: 1"
  end

  test "require" do
    assert_format "require Foo"
    "require(Foo)" ~> "require Foo"
    "require    Foo" ~> "require Foo"
    assert_format "require Foo.Bar"
    """
    require Really.Long.Module.Name, Another.Really.Long.Module.Name
    """ ~> """
    require Really.Long.Module.Name,
            Another.Really.Long.Module.Name
    """
  end

  test "import" do
    assert_format "import Foo"
    "import(Foo)" ~> "import Foo"
    "import    Foo" ~> "import Foo"
    "import Foo.Bar" ~> "import Foo.Bar"
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
    assert_format "alias Foo"
    "alias(Foo)" ~> "alias Foo"
    "alias    Foo" ~> "alias Foo"
    assert_format "alias Foo.Bar"
    assert_format "alias String, as: S"
    "alias Element.{Storm,Earth,Fire}" ~> "alias Element.{Storm, Earth, Fire}"
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
    assert_format "alias Really.Long.Module.Name.That.Does.Not.Fit.In.Width"
  end

  test "doctest" do
    assert_format "doctest Foo"
  end

  test "defstruct" do
    assert_format "defstruct attrs"
    assert_format "defstruct []"
    assert_format "defstruct [:size, :age]"
    "defstruct [size: 1, age: 2]" ~> "defstruct size: 1, age: 2"
  end

  test "use" do
    assert_format "use ExUnit.Case, async: true"
  end

  test "send" do
    assert_format "send my_pid, :hello"
  end

  test "call qualified by atom from another call" do
    assert_format "Mix.shell.info :ok"
  end

  test "call with keyword list not as last arg" do
    assert_format "print_tree [normal: app], opts"
  end

  test "unquoted function name call" do
    assert_format "unquote(callback).()"
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
