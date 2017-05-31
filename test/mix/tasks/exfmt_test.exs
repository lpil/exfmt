defmodule Mix.Tasks.ExfmtTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  describe "mix exfmt" do
    test "with no args" do
      io = capture_io(fn->
        Mix.Tasks.Exfmt.run([])
      end)
      assert io =~ "USAGE"
      assert io =~ "mix exfmt path/to/file.ex"
    end

    test "path to unknown file" do
      io = capture_io(fn->
        Mix.Tasks.Exfmt.run(["unknown-path-here"])
      end)
      assert io =~ "Error: No such file or directory"
      assert io =~ "unknown-path-here"
    end

    test "file with syntax error" do
      io = capture_io(fn->
        Mix.Tasks.Exfmt.run(["priv/examples/syntax_error.ex"])
      end)
      assert io =~ "Error: syntax error before"
    end

    test "file with valid syntax" do
      io = capture_io(fn->
        Mix.Tasks.Exfmt.run(["priv/examples/ok.ex"])
      end)
      assert io == ":ok\n"
    end
  end
end
