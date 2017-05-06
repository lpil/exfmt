defmodule Exfmt.AST.UtilTest do
  use ExUnit.Case, async: true
  alias Exfmt.AST.Util

  test "split_do_block" do
    assert Util.split_do_block([]) == {[], []}
    assert Util.split_do_block([1]) == {[1], []}
    assert Util.split_do_block([1, 2]) == {[1, 2], []}
    assert Util.split_do_block([1, 2, 3]) == {[1, 2, 3], []}
    assert Util.split_do_block([1, 2, [do: 3]]) == {[1, 2], [do: 3]}
    assert Util.split_do_block([1, 2, [do: 3], 4]) == {[1, 2, [do: 3], 4], []}
    assert Util.split_do_block([1, [do: 2, else: 3]]) == {[1], [do: 2, else: 3]}
  end
end
