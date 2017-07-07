defmodule Exfmt.Integration.BlockTest do
  use ExUnit.Case
  import Support.Integration

  test "blocks" do
    assert_format """
    1 + 1
    """
    assert_format """
    1 + 1
    2 / 3
    """
    assert_format """
    run 1
    run 2
    run 3
    """
  end

  test "do end blocks" do
    assert_format """
    test "hello" do
      :ok
    end
    """
    assert_format """
    if x do
      :ok
    else
      :ok
    end
    """
    assert_format """
    run do
      []
    end
    """
    assert_format """
    App.run do
      []
    end
    """
  end

  test "__block__/0 call" do
    assert_format """
    __block__()
    """
  end

  # FIXME: Can we preserve this as a call rather than
  # rendering as a block literal??
  test "__block__/1 call" do
    assert_format """
    1
    """
  end
end
