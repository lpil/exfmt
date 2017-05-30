defmodule Exfmt.AstTest do
  use ExUnit.Case, async: true
  alias Exfmt.Ast
  doctest Ast, import: true
  import Ast

  @newline {:"#newline", [], []}

  describe "preprocess/1" do
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
        preprocess(ast)
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
        preprocess(ast)
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
end
