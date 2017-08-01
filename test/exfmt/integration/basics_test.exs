defmodule Exfmt.Integration.BasicsTest do
  use ExUnit.Case
  import Support.Integration

  test "ints" do
    assert_format "0\n"
    assert_format "1\n"
    assert_format "2\n"
    assert_format "-0\n"
    assert_format "-1\n"
    assert_format "-2\n"
  end

  test "large ints" do
    assert_format "10000\n"
    assert_format "100_000\n"
    assert_format "1_000_000\n"

    "1000" ~> "1000\n"
    "10000" ~> "10000\n"
    "99999" ~> "99999\n"
    "100000" ~> "100_000\n"
    "1000000" ~> "1_000_000\n"
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
    assert_format ":ok\n"
    assert_format ":\"hello-world\"\n"
    assert_format ":\"[]\"\n"
    assert_format ":_\n"
    assert_format ~s(:"Elixir.Exfmt"\n)
  end

  test "aliases" do
    "String" ~> "String\n"
    "My.String" ~> "My.String\n"
    "App.Web.Controller" ~> "App.Web.Controller\n"
    "__MODULE__.Helper" ~> "__MODULE__.Helper\n"
  end

  test "alias with quoted base mod" do
    assert_format """
    alias unquote(Inspect).{Algebra}
    """
  end

  test "aliases with variable part" do
    assert_format """
    One.x.Three
    """
  end

  test "keyword lists" do
    "[]" ~> "[]\n"
    "[a: 1]" ~> "[a: 1]\n"
    "[ b:  {} ]" ~> "[b: {}]\n"
    "[a: 1, b: 2]" ~> "[a: 1, b: 2]\n"
    "[{:a, 1}]" ~> "[a: 1]\n"
  end

  test "keyword lists with special atom keys" do
    assert_format """
    [nil: :magenta, true: 1, false: 2]
    """
  end

  test "charlists" do
    "''" ~> "[]\n"
    "'a'" ~> "[97]\n" # TODO: Hmm...
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

  test "really long lists" do
    assert_format """
    [48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48,
     48]
    """
  end


  test "tuples" do
    "{}" ~> "{}\n"
    "{1}" ~> "{1}\n"
    "{1,2}" ~> "{1, 2}\n"
    "{1,2,3}" ~> "{1, 2, 3}\n"
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

  test "module attribute with block call arg" do
    assert_format """
    @ok (case ok do
           _ ->
             :ok
         end)
    """
  end

  test "Access protocol" do
    assert_format "keys[:name]\n"
    assert_format "conn.assigns[:safe_mode_active]\n"
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

  test "case with comments in body" do
    """
    case data do
      # bad
      %{} ->
        :ok
    end
    """ ~> """
    case data do
      # bad
      %{} ->
        :ok
    end
    """
  end

  test "with (<- op is has own group)" do
    assert_format """
    with {:ok, path} <- get_path(x, y, z),
         {:ok, out} <- run(path) do
      IO.write out
    end
    """
  end

  test "infix op with lhs with block" do
    assert_format """
    assert (run do
               :ok
             end) == :ok
    """
  end

  test "infix op with rhs with block" do
    assert_format """
    assert :ok == (run do
               :ok
             end)
    """
  end

  test "infix op with attribute assignment argument" do
    assert_format """
    (@value 1) == :ok
    """
    assert_format """
    :ok == (@value 1)
    """
    assert_format """
    :ok == @value
    """
  end

  test "infix op with block argument" do
    assert_format """
    _ = (nil
      nil)
    """
  end

  test "direct call to __aliases__/1" do
    assert_format """
    __aliases__(args)
    """
  end
end
