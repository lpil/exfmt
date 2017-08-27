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
    @spec start_link(module(), term(number), Keyword.t()) :: on_start()
    """ ~> """
    @spec start_link(
        module(),
        term(number),
        Keyword.t
      )
      :: on_start()
    """
    assert_format """
    @spec break() :: doc_break()
    """
  end

  test "@spec wrapping" do
    # right side too long
    assert_format """
    @spec run(String.t)
      :: atom
      | atom
      | atom
      | atom
      | atom
      | atom
    """
    # left side too long
    assert_format """
    @spec run(
        String.t,
        term,
        [meta],
        options
      )
      :: atom | atom | atom | atom | atom
    """
    # right and left sides too long
    assert_format """
    @spec run(
        String.t,
        term,
        [meta],
        options
      )
      :: atom
      | atom
      | atom
      | atom
      | atom
      | atom
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
