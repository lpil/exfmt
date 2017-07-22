defmodule Mix.Tasks.ExfmtTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  describe "mix exfmt" do
    test "with no args" do
      io = capture_io(:stderr, fn->
        Mix.Tasks.Exfmt.run([])
      end)
      assert io =~ "USAGE"
      assert io =~ "mix exfmt path/to/file.ex"
    end

    test "path to unknown file" do
      result = Mix.Tasks.Exfmt.process(["unknown-path-here"])
      assert result.stderr =~ "no such file or directory"
      assert result.stderr =~ "unknown-path-here"
    end

    test "file with syntax error" do
      result = Mix.Tasks.Exfmt.process(["priv/examples/syntax_error.ex"])
      assert result.stderr =~ "Error: syntax error before"
    end

    test "stdin with valid syntax" do
      capture_io(" :ok ", fn ->
        result = Mix.Tasks.Exfmt.process(["--stdin"])
        assert result.stdout =~ ":ok\n"
      end)
    end

    test "file with valid syntax via shell" do
      io = capture_io(fn->
        Mix.Tasks.Exfmt.run(["priv/examples/ok.ex"])
      end)
      assert io == ":ok\n"
    end

    test "stdin with valid syntax via shell" do
      io = capture_io(" :ok ", fn->
        Mix.Tasks.Exfmt.run(["--stdin"])
      end)
      assert io == ":ok\n"
    end
  end
end
