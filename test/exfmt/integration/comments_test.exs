defmodule Exfmt.Integration.CommentsTest do
  use ExUnit.Case
  import Support.Integration, only: [~>: 2, assert_format: 1]

  test "comments" do
    """
    # Hello
    """ ~> """
    # Hello
    """
    """
    # Hello
    # World
    """ ~> """
    # Hello
    # World
    """
  end

  test "call comments" do
    assert_format """
    # Hello1
    # World1
    call()
    """
    assert_format """
    call()
    # Hello2
    # World2
    """
    """
    call() # Hello3
    """ ~> """
    call()
    # Hello3
    """
    """
    call() # Hello
    # World
    """ ~> """
    call()
    # Hello
    # World
    """
  end

  test "comment arg containing comment" do
    assert_format """
    call(# Hello
         arg())
    """
  end

  test "comment arg containing comment in last place" do
    """
    call(arg()
        # Hello
    )

    """ ~> """
    call arg()
    # Hello

    """
  end

  test "defs" do
    """
    # one a
    # one b
    # one c
    defp one do
      1
    end
    """ ~> """
    # one a
    # one b
    # one c
    defp one do
      1
    end
    """
  end

  test "comments at both ends of block" do
    """
    # one
    call()
    # two
    again()
    # three
    """ ~> """
    # one
    call()
    # two
    again()
    # three
    """
  end
end
