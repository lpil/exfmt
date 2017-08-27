defmodule Exfmt.Integration.ModuleTest do
  use ExUnit.Case, async: true
  import Support.Integration

  test "multiple functions" do
    assert_format """
    defmodule App do
      def run do
        :ok
      end


      def stop do
        :ok
      end
    end
    """
  end

  test "multiple clauses of a function" do
    assert_format """
    defmodule App do
      def run(1) do
        :ok
      end

      def run(2) do
        :ok
      end
    end
    """
  end

  test "functions with attributes before" do
    assert_format """
    defmodule App do
      @doc false
      def run do
        :ok
      end


      @doc false
      def stop do
        :ok
      end
    end
    """
  end

  test "modules with attrs and defs" do
    assert_format """
    defmodule App do
      @foo 1
      @bar 2

      @doc false
      def run do
        :ok
      end
    end
    """
  end

  test "modules with moduledoc, attrs and defs" do
    assert_format """
    defmodule App do
      @moduledoc false

      @foo 1
      @bar 2

      @doc false
      def run do
        :ok
      end
    end
    """
  end

  test "module with defdelegates" do
    assert_format """
    defmodule App do
      @foo 1

      defdelegate run(name), to: Lib
      defdelegate stop(name), to: Lib

      @bar 2
    end
    """
  end

  test "def with spec and doc" do
    """
    defmodule App do
      @doc false
      @spec run(integer) :: :ok
      def run(_), do: :ok
    end
    """ ~> """
    defmodule App do
      @doc false
      @spec run(integer) :: :ok
      def run(_) do
        :ok
      end
    end
    """
  end

  test "README example" do
    """
    defmodule MyApp, do: (
        use( SomeLib )
        def run( data ), do: {
            :ok,
            data
        }
    )
    """ ~> """
    defmodule MyApp do
      use SomeLib

      def run(data) do
        {:ok, data}
      end
    end
    """
  end

  test "calls at top level of do block" do
    assert_format """
    defmodule FooMod do
      save use(Foo)
      save import(Foo)
      save require(Foo)
      save alias(Foo)
      save doctest(Foo)
    end
    """
  end

  test "grouping use, import, alias, require calls" do
    """
    use GenServer
    use PortMapper
    import Bitwise
    import Kernel, except: [length: 1]
    alias Mix.Utils
    alias MapSet, as: Set
    require Logger
    require Printer
    """ ~> """
    use GenServer
    use PortMapper

    import Bitwise
    import Kernel, except: [length: 1]

    alias Mix.Utils
    alias MapSet, as: Set

    require Logger
    require Printer
    """
    assert_format """
    defmodule App do
      use GenServer
      use PortMapper

      import Bitwise
      import Kernel, except: [length: 1]

      alias Mix.Utils
      alias MapSet, as: Set

      require Logger
      require Printer

      def run() do
        :ok
      end
    end
    """
  end
end
