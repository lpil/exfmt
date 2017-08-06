defmodule Exfmt.AstTest do
  use ExUnit.Case, async: true
  alias Exfmt.Ast
  doctest Ast, import: true
  import Ast

  @newline {:"#newline", [], []}

  describe "insert_empty_lines/1" do
    test "newline insertion between function clauses" do
      ast = Code.string_to_quoted! """
        defmodule App do
          def int(:one) do
            1
          end

          def int(:two) do
            2
          end
        end
      """
      assert {:defmodule, _, [{:__aliases__, _, [:App]}, [do: body]]} =
        insert_empty_lines(ast)
      assert {:__block__, [], [one, @newline, two]} = body
      assert {:def, _, [{:int, _, [:one]}, [do: 1]]} = one
      assert {:def, _, [{:int, _, [:two]}, [do: 2]]} = two
    end

    test "double newline insertion between different functions" do
      ast = Code.string_to_quoted! """
        defmodule App do
          def one do
            1
          end

          def two do
            2
          end
        end
      """
      assert {:defmodule, _, [{:__aliases__, _, [:App]}, [do: body]]} =
        insert_empty_lines(ast)
      assert {:__block__, [], [one, @newline, @newline, two]} = body
      assert {:def, _, [{:one, _, nil}, [do: 1]]} = one
      assert {:def, _, [{:two, _, nil}, [do: 2]]} = two
    end
  end

  describe "group_by_def/4" do
    test "empty group" do
      assert group_by_def([]) == [[]]
    end

    test "misc values" do
      exprs = [{:@, [], [{:one, [], [1]}]},
               {:@, [], [{:two, [], [2]}]},
               {:@, [], [{:three, [], [3]}]}]
      expected = [[{:@, [], [{:three, [], [3]}]},
                   {:@, [], [{:two, [], [2]}]},
                   {:@, [], [{:one, [], [1]}]}]]
      assert group_by_def(exprs) == expected
    end

    test "two defs" do
      exprs = [{:def, [], [{:one, [], Elixir}, [do: 1]]},
               {:def, [], [{:two, [], Elixir}, [do: 2]]}]
      expected = [[{:def, [], [{:two, [], Elixir}, [do: 2]]}],
                  [{:def, [], [{:one, [], Elixir}, [do: 1]]}]]
      assert group_by_def(exprs) == expected
    end

    test "two defs with attributes" do
      exprs = [{:@, [], [{:doc, [], [false]}]},
               {:def, [], [{:one, [], Elixir}, [do: 1]]},
               {:@, [], [{:doc, [], [false]}]},
               {:def, [], [{:two, [], Elixir}, [do: 2]]}]
      expected = [[{:def, [], [{:two, [], Elixir}, [do: 2]]},
                   {:@, [], [{:doc, [], [false]}]}],
                  [{:def, [], [{:one, [], Elixir}, [do: 1]]},
                   {:@, [], [{:doc, [], [false]}]}]]
      assert group_by_def(exprs) == expected
    end
  end

  describe "eq?/2" do
    test "numbers" do
      assert eq?(quote do 1 end, quote do 1 end)
      assert eq?(quote do 1.0 end, quote do 1.0 end)
      refute eq?(quote do 2.0 end, quote do 1.0 end)
    end

    test "atoms" do
      assert eq?(quote do :ok end, quote do :ok end)
      refute eq?(quote do :ok end, quote do nil end)
      assert eq?(quote do true end, quote do true end)
      assert eq?(quote do false end, quote do false end)
      refute eq?(quote do true end, quote do false end)
      assert eq?(quote do nil end, quote do nil end)
    end

    test "strings" do
      assert eq?(quote do "hi\n" end,
                 quote do
                   """
                   hi
                   """
                 end)
      refute eq?(quote do "1" end, quote do "2" end)
    end

    test "lists" do
      assert eq?(quote do [1, 2, 3] end, quote do [1, 2, 3] end)
      refute eq?(quote do [3, 2, 1] end, quote do [1, 2, 3] end)
      refute eq?(quote do [1] end, quote do [1, 2] end)
    end

    test "2 item tuples" do
      assert eq?(quote do {:ok, 1} end, quote do {:ok, 1} end)
      refute eq?(quote do {:ok, 1} end, quote do {:ok, 2} end)
    end

    test "calls" do
      assert eq?(quote do run(1) end, quote do run(1) end)
      refute eq?(quote do run(1) end, quote do stop(1) end)
      refute eq?(quote do run(1) end, quote do run(1, 2) end)
    end

    test "calls with different meta" do
      assert eq?({:run, [line: 1], []}, {:run, [line: 1000], []})
    end

    test "2 elem tuples with calls with different meta" do
      assert eq?({:error, {:run, [line: 1], []}},
                 {:error, {:run, [line: 1000], []}})
      assert eq?({{:run, [line: 1], []}, :error},
                 {{:run, [line: 1000], []}, :error})
    end

    test "blocks of one and single expressions are eq" do
      single = quote do
        def available?(dep), do: not diverged?(dep)
      end
      block = quote do
        def available?(dep) do
          not diverged?(dep)
        end
      end
      assert eq?(block, single)
      assert eq?(single, block)
    end
  end
end

