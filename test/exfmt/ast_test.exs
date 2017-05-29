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
end
