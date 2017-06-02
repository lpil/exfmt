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
      assert extract_comments(~S(x = [?", ?'])) == {:ok, []}
    end

    test "sigil" do
      assert extract_comments("~s||") == {:ok, []}
      assert extract_comments("~s[a]") == {:ok, []}
      assert extract_comments("~s/q /") == {:ok, []}
      assert extract_comments("~s{1 }") == {:ok, []}
      assert extract_comments("~s(aa)") == {:ok, []}
      assert extract_comments("~s<##>") == {:ok, []}
    end

    test "sigil with content that looks like comment" do
      assert extract_comments("~s(# nope)") == {:ok, []}
    end

    test "capital sigil with content that looks like interp" do
      code = ~S"""
      ~S(#{ # nope })
      """
      assert extract_comments(code) == {:ok, []}
    end

    test "comment preceeding string interpolation" do
      code = ~S"""
      # 1
      "#{}"
      """
      assert extract_comments(code) == {:ok, [{:"#", [line: 1], [" 1"]}]}
    end

    test "docstring with content that looks like comment" do
      code = ~S(
      """

      # Nope!

      """
      # Yes!
      )
      assert extract_comments(code) == {:ok, [{:"#", [line: 7], [" Yes!"]}]}
    end

    test "sigil docstring with content that looks like comment" do
      code = ~S(
      ~S"""

      # Nope!

      """
      # Yes!
      )
      assert extract_comments(code) == {:ok, [{:"#", [line: 7], [" Yes!"]}]}
    end
  end

  describe "merge/2" do
    test "nil ast and no comments" do
      assert merge([], nil) == {:"#comment_block", [], []}
    end

    test "nil ast and some comments" do
      comments = [{:"#", [line: 2], [""]}, {:"#", [line: 1], [""]}]
      expected = [{:"#", [line: 1], [""]}, {:"#", [line: 2], [""]}]
      assert merge(comments, nil) == {:"#comment_block", [], expected}
    end

    test "comments before call" do
      comments = [{:"#", [line: 1], [""]}]
      ast = {:ok, [line: 2], []}
      assert merge(comments, ast) ==
        {:"#comment_block", [], [{:"#", [line: 1], [""]}, {:ok, [line: 2], []}]}
    end

    test "multi-line comments before call" do
      comments = [{:"#", [line: 3], ["c"]},
                  {:"#", [line: 2], ["b"]},
                  {:"#", [line: 1], ["a"]}]
      ast = {:ok, [line: 4], []}
      assert {:"#comment_block", [], children} = merge(comments, ast)
      assert children == [{:"#", [line: 1], ["a"]},
                          {:"#", [line: 2], ["b"]},
                          {:"#", [line: 3], ["c"]},
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
      assert {:"#comment_block", [], children} = merge(comments, ast)
      assert children == [{:__block__, [], [1, 2.0, "", :ok, [k: 1], []]},
                          {:"#", [line: 1], [""]}]
    end

    test "comments in function call" do
      ast = Code.string_to_quoted! """
      explode(# One here
              one(),
              # Two here
              two())
      """
      comments =
        [{:"#", [line: 3], [" Two here"]}, {:"#", [line: 1], [" One here"]}]
      assert {:explode, [line: 1], [arg1, arg2]} = merge(comments, ast)
      assert {:"#comment_block", [], arg1_children} = arg1
      assert arg1_children ==
        [{:"#", [line: 1], [" One here"]}, {:one, [line: 2], []}]
      assert {:"#comment_block", [], arg2_children} = arg2
      assert arg2_children ==
        [{:"#", [line: 3], [" Two here"]}, {:two, [line: 4], []}]
    end

    test "comment preceeding string interp" do
      ast = Code.string_to_quoted!(~S(
      # 1
      "#{}"
      ))
      comments = [{:"#", [line: 1], [" 1"]}]
      assert {:"#comment_block", [], [comment, string]} = merge(comments, ast)
      assert hd(comments) == comment
      assert {:<<>>, _, _} = string
    end
  end
end
