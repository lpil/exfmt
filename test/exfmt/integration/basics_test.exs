defmodule Exfmt.Integration.BasicsTest do
  use ExUnit.Case
  import Support.Integration

  test "ints" do
    assert_format "0"
    assert_format "1"
    assert_format "2"
    assert_format "-0"
    assert_format "-1"
    assert_format "-2"
  end

  test "floats" do
    "0.000" ~> "0.0"
    assert_format "1.111"
    assert_format "2.08"
    "-0.000" ~> "-0.0"
    "-0.123" ~> "-0.123"
    "-1.123" ~> "-1.123"
    "-2.123" ~> "-2.123"
  end

  test "atoms" do
    assert_format ":ok"
    assert_format ":\"hello-world\""
    assert_format ":\"[]\""
    assert_format ":_"
    assert_format ~s(:"Elixir.Exfmt")
  end

  test "aliases" do
    assert_format "String"
    assert_format "My.String"
    assert_format "App.Web.Controller"
    assert_format "__MODULE__.Helper"
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
    assert_format "[]"
    assert_format "[a: 1]"
    "[ b:  {} ]" ~> "[b: {}]"
    assert_format "[a: 1, b: 2]"
    "[{:a, 1}]" ~> "[a: 1]"
  end

  test "keyword lists with special atom keys" do
    assert_format """
    [nil: :magenta, true: 1, false: 2]
    """
  end

  test "charlists" do
    "''" ~> "[]"
    "'a'" ~> "[97]" # TODO: Hmm...
  end

  test "lists" do
    "[ ]" ~> "[]"
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
    assert_format "{}"
    assert_format "{1}"
    "{1,2}" ~> "{1, 2}"
    "{1,2,3}" ~> "{1, 2, 3}"
  end

  test "variables" do
    assert_format "some_var"
    assert_format "_another_var"
    assert_format "thing1"
  end

  test "module attributes" do
    assert_format "@size"
    assert_format "@foo 1"
    assert_format "@tag :skip"
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
    assert_format "keys[:name]"
    assert_format "conn.assigns[:safe_mode_active]"
    """
    some_list[
    :name
    ]
    """ ~> """
    some_list[:name]
    """
  end

  test "maths" do
    assert_format "1 + 2"
    assert_format "1 - 2"
    assert_format "1 * 2"
    assert_format "1 / 2"
    assert_format "1 * 2 + 3"
    assert_format "1 + 2 * 3"
    assert_format "(1 + 2) * 3"
    assert_format "(1 - 2) * 3"
    assert_format "1 / 2 + 3"
    assert_format "1 + 2 / 3"
    assert_format "(1 + 2) / 3"
    assert_format "(1 - 2) / 3"
    assert_format "1 * 2 / 3"
    assert_format "1 / 2 * 3"
    """
    something_really_really_really_really_long + 2
    """ ~> """
    something_really_really_really_really_long +
      2
    """
  end

  test "list patterns" do
    "[head1, head2|tail]" ~> "[head1, head2 | tail]"
  end

  test "magic variables" do
    assert_format "__MODULE__"
    assert_format "__CALLER__"
  end

  test "booleans" do
    assert_format "true"
    assert_format "false"
  end

  test "||" do
    assert_format "true || true"
  end

  test "&&" do
    assert_format "true && true"
  end

  test "or" do
    assert_format "true or true"
  end

  test "and" do
    assert_format "true and true"
  end

  test "in" do
    assert_format "x in [1, 2]"
  end

  test "~>" do
    assert_format "x ~> [1, 2]"
  end

  test ">>>" do
    assert_format "x >>> [1, 2]"
  end

  test "<>" do
    assert_format "x <> y"
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
end
