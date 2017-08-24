defmodule Exfmt.Integration.TypespecTest do
  use ExUnit.Case
  import Support.Integration

  test "@spec" do
    "@spec bar() :: 1" ~> "@spec bar() :: 1\n"
    "@spec ok :: :ok" ~> "@spec ok :: :ok\n"
    """
    @spec run(String.t, [tern]) :: atom
    """ ~> """
    @spec run(String.t, [tern]) :: atom
    """
    """
    @spec run(String.t) :: atom | String.t | :hello
    """ ~> """
    @spec run(String.t)
      :: atom | String.t | :hello
    """
    """
    @spec start_link(module(), term(number), Keyword.t()) :: on_start()
    """ ~> """
    @spec start_link(module(),
                     term(number),
                     Keyword.t)
      :: on_start()
    """
    assert_format """
    @spec break() :: doc_break()
    """
  end

  test "@spec 2" do
    """
    @spec run(String.t) :: atom | String.t | :hello | :world
    """ ~> """
    @spec run(String.t)
      :: atom | String.t | :hello | :world
    """
    """
    @spec run(String.t, term, opts) :: atom | String.t | :hello | :world | number
    """ ~> """
    @spec run(String.t, term, opts)
      :: atom
      | String.t
      | :hello
      | :world
      | number
    """
  end

  test "function type in spec" do
    assert_format """
    @spec id((() -> term)) :: (() -> term)
    """
    assert_format """
    @spec id(((t) -> t)) :: ((t) -> t)
    """
  end
end
