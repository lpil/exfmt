defmodule Exfmt.EscriptTest do
  use Exfmt.FsCase, async: true

  @test_file1 "test1.ex"
  @test_file2 "test2.ex"

  test_in_tmp "escript rewrites file" do
    File.write! @test_file1, """
    defmodule MyApp, do: (
        use( SomeLib )
        def run( data ), do: {
            :ok,
            data
        }
    )
    """

    Exfmt.Escript.main([@test_file1])

    assert File.read!(@test_file1) == """
    defmodule MyApp do
      use SomeLib

      def run(data) do
        {:ok, data}
      end
    end
    """
  end

  test_in_tmp "escript rewrites files" do
    File.write! @test_file1, """
    defmodule MyApp, do: (
        use( SomeLib )
        def run( data ), do: {
            :ok,
            data
        }
    )
    """

    File.write! @test_file2, """
    defmodule MyApp2, do: (
        use( SomeLib )
        def run( data ), do: {
            :ok,
            data
        }
    )
    """

    Exfmt.Escript.main([@test_file1, @test_file2])

    assert File.read!(@test_file1) == """
    defmodule MyApp do
      use SomeLib

      def run(data) do
        {:ok, data}
      end
    end
    """

    assert File.read!(@test_file2) == """
    defmodule MyApp2 do
      use SomeLib

      def run(data) do
        {:ok, data}
      end
    end
    """
  end

  test_in_tmp "escript obeys max line length" do
    File.write! @test_file1, """
    defmodule MyApp, do: (
        use( SomeLib )
        def run( data ), do: {
            :ok,
            data
        }
    )
    """

    Exfmt.Escript.main(["--max-width", "10", @test_file1])

    assert File.read!(@test_file1) == """
    defmodule MyApp
    do
      use SomeLib

      def run(data)
      do
        {:ok,
         data}
      end
    end
    """
  end
end
