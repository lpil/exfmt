defmodule Exfmt.CommentTest do
  use ExUnit.Case, async: true
  import Exfmt.Comment

  describe "extract_comments/1" do
    test "none" do
      assert extract_comments("") == {:ok, []}
    end

    test "empty comment" do
      assert extract_comments("#") == {:ok, [{:"#", 1, ""}]}
      assert extract_comments("#\n") == {:ok, [{:"#", 1, ""}]}
    end

    test "comment 1" do
      code = """
      # Hi!
      """
      assert extract_comments(code) == {:ok, [{:"#", 1, " Hi!"}]}
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
      assert extract_comments(code) == {:ok, [{:"#", 3, " a comment!"}]}
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
      assert extract_comments(code) == {:ok, [{:"#", 4, " Hi!"}]}
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
  end
end
