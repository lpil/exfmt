defmodule Exfmt.Integration.CommentsTest do
  use ExUnit.Case
  import Support.Integration, only: [~>: 2]

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
    """
    # Hello
    # World
    call()
    """ ~> """
    # Hello
    # World
    call()
    """
    """
    call()
    # Hello
    # World
    """ ~> """
    call()
    # Hello
    # World
    """
    """
    call() # Hello
    """ ~> """
    call()
    # Hello
    """
    """
    call() # Hello
    # World
    """ ~> """
    call()
    # Hello
    # World
    """
    """
    call(# Hello
         arg())
    """ ~> """
    call(# Hello
         arg())
    """
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
