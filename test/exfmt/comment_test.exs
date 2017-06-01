defmodule Exfmt.CommentTest do
  use ExUnit.Case, async: true
  import Exfmt.Comment
  doctest Exfmt.Comment, import: true

  describe "extract_comments/1" do
    test "none" do
      assert extract_comments("") == {:ok, []}
    end

    test "empty comment" do
      assert extract_comments("#") == {:ok, [{:"#", [line: 1], [""]}]}
      assert extract_comments("#\n") == {:ok, [{:"#", [line: 1], [""]}]}
    end

    test "comment 1" do
      code = """
      # Hi!
      """
      assert extract_comments(code) == {:ok, [{:"#", [line: 1], [" Hi!"]}]}
    end

    test "code without comments" do
      code = """
      defmodule SomeModule do
        def some_function(x) do
          {:ok, x}
        end
      end
      """
      assert extract_comments(code) == {:ok, []}
    end

    test "comment 2" do
      code = """
      1
      2
      # a comment!
      4
      5
      """
      assert extract_comments(code) == {:ok, [{:"#", [line: 3], [" a comment!"]}]}
    end

    test "hash in string" do
      code = """
      "# not a comment"
      """
      assert extract_comments(code) == {:ok, []}
    end

    test "interp in string" do
      code = ~S"""
      "Hi #{name}!"
      """
      assert extract_comments(code) == {:ok, []}
    end

    test "comment after multi-line string" do
      code = ~S"""
      "1
      2 # Not a comment
      3"
      # Hi!
      """
      assert extract_comments(code) == {:ok, [{:"#", [line: 4], [" Hi!"]}]}
    end

    #
    # FIXME: Comments inside interpolation are currently discarded.
    #
    test "comment in interp in string" do
      code = ~S(
      """
      1 #{2 # A comment!
      }
      """
      )
      assert extract_comments(code) == {:ok, []}
    end

    test "\" char literals" do
      code = ~S(x = [?", ?'])
      assert extract_comments(code) == {:ok, []}
    end
  end

  describe "merge/2" do
    test "nil ast and no comments" do
      assert merge([], nil) == {:__block__, [], []}
    end

    test "nil ast and some comments" do
      comments = [{:"#", [line: 2], [""]}, {:"#", [line: 1], [""]}]
      expected = [{:"#", [line: 1], [""]}, {:"#", [line: 2], [""]}]
      assert merge(comments, nil) == {:__block__, [], expected}
    end

    test "comments before call" do
      comments = [{:"#", [line: 1], ""}]
      ast = {:ok, [line: 2], []}
      assert merge(comments, ast) ==
        {:__block__, [], [{:"#", [line: 1], ""}, {:ok, [line: 2], []}]}
    end

    test "multi-line comments before call" do
      comments = [{:"#", [line: 3], "c"},
                  {:"#", [line: 2], "b"},
                  {:"#", [line: 1], "a"}]
      ast = {:ok, [line: 4], []}
      assert {:__block__, [], children} = merge(comments, ast)
      assert children == [{:"#", [line: 1], "a"},
                          {:"#", [line: 2], "b"},
                          {:"#", [line: 3], "c"},
                          {:ok, [line: 4], []}]
    end

    test "ast nodes with literal syntax" do
      ast = Code.string_to_quoted! """
      1
      2.0
      ""
      :ok
      [k: 1]
      ''
      """
      comments = [{:"#", [line: 1], [""]}]
      assert {:__block__, [], children} = merge(comments, ast)
      assert children == [1, 2.0, "", :ok, [k: 1], [], {:"#", [line: 1], [""]}]
    end

    test "comments in function call" do
      ast = Code.string_to_quoted! """
      explode(# One here
              one(),
              # Two here
              two())
      """
      comments =
        [{:"#", [line: 1], [" One here"]}, {:"#", [line: 3], [" Two here"]}]
      assert {:explode, [line: 1], [arg1, arg2]} = merge(comments, ast)
      assert {:__block__, [], arg1_children} = arg1
      assert arg1_children ==
        [{:"#", [line: 1], [" One here"]}, {:one, [line: 2], []}]
      assert {:__block__, [], arg2_children} = arg2
      assert arg2_children ==
        [{:"#", [line: 3], [" Two here"]}, {:two, [line: 4], []}]
    end
  end
end
