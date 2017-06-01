defmodule Exfmt.Integration.BasicsTest do
  use ExUnit.Case
  import Support.Integration, only: [~>: 2]

  test "ints" do
    "0" ~> "0\n"
    "1" ~> "1\n"
    "2" ~> "2\n"
    "-0" ~> "-0\n"
    "-1" ~> "-1\n"
    "-2" ~> "-2\n"
  end

  test "floats" do
    "0.000" ~> "0.0\n"
    "1.111" ~> "1.111\n"
    "2.08" ~> "2.08\n"
    "-0.000" ~> "-0.0\n"
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
    "%{1 => 1, 2 => 2}" ~> "%{1 => 1, 2 => 2}\n"
  end

  test "map upsert %{map | key: value}" do
    "%{map | key: value}" ~> "%{map | key: value}\n"
  end

  test "structs" do
    "%Person{}" ~> "%Person{}\n"
    "%Person{age: 1}" ~> "%Person{age: 1}\n"
    "%Person{timmy | age: 1}" ~> "%Person{timmy | age: 1}\n"
    """
    %LongerNamePerson{timmy | name: "Timmy", age: 1}
    """ ~> """
    %LongerNamePerson{timmy |
                      name: "Timmy",
                      age: 1}
    """
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
    ~S"~r/\/)/" ~> "~r(/\\))\n"
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
    [0,1,2,3,4,5,6,7,8,9,10,11,12]
    """ ~> """
    [0,
     1,
     2,
     3,
     4,
     5,
     6,
     7,
     8,
     9,
     10,
     11,
     12]
    """
  end

  test "tuples" do
    "{}" ~> "{}\n"
    "{1}" ~> "{1}\n"
    "{1,2}" ~> "{1, 2}\n"
    "{1,2,3}" ~> "{1, 2, 3}\n"
  end

  test "captured functions" do
    "&inspect/1" ~> "&inspect/1\n"
    "&inspect(&1)" ~> "&inspect(&1)\n"
    "&merge(&2, &1)" ~> "&merge(&2, &1)\n"
    "&(&2 + &1)" ~> "& &2 + &1\n"
    "(& &1.name)" ~> "& &1.name\n"
  end

  test "calling captured functions" do
    "(&inspect/1).()" ~> "(&inspect/1).()\n"
    "(&(&1 <> x)).()" ~> "(& &1 <> x).()\n"
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
    @sizes [1,2,3,4,5,6,7,8,9,10,11]
    """ ~> """
    @sizes [1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            11]
    """
  end

  test "Access protocol" do
    "keys[:name]" ~> "keys[:name]\n"
    "some_list[\n   :name\n]" ~> "some_list[:name]\n"
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
    """
    @spec run(String.t) :: atom | String.t | :hello
    """ ~> """
    @spec run(String.t)
          :: atom | String.t | :hello
    """
    """
    @spec run(String.t) :: atom | String.t | :hello | :world
    """ ~> """
    @spec run(String.t)
          :: atom
          | String.t
          | :hello
          | :world
    """
  end

  test "list patterns" do
    "[head1, head2|tail]" ~> "[head1, head2 | tail]\n"
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

  test "functions with guards" do
    """
    def one?(x) when x in [:one, "one"] do
      true
    end
    """ ~> """
    def one?(x) when x in [:one, "one"] do
      true
    end
    """
  end

  test "comments" do
    """
    # Hello
    """ ~> """
    # Hello
    """
    """
    # Hello
    # World
    """ ~> """
    # Hello
    # World
    """
    """
    # Hello
    # World
    call()
    """ ~> """
    # Hello
    # World
    call()
    """
    """
    call()
    # Hello
    # World
    """ ~> """
    call()
    # Hello
    # World
    """
    """
    call() # Hello
    """ ~> """
    call()
    # Hello
    """
    """
    call() # Hello
    # World
    """ ~> """
    call()
    # Hello
    # World
    """
    """
    call(# Hello
         arg())
    """ ~> """
    call(# Hello
         arg())
    """
    """
    call(arg()
        # Hello
    )

    """ ~> """
    call arg()
    # Hello
    """
  end

  @tag :skip
  test "with"

  @tag :skip
  test "string interpolation"

  @tag :skip
  test "binary syntax"

  @tag :skip
  test "capital S sigil does not escape" do
    ~S"""
    ~S(#{this isn't interp})
    """
  end
end
