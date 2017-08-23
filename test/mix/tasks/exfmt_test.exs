defmodule Mix.Tasks.ExfmtTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  describe "mix exfmt" do
    test "with no args" do
      io = capture_io(:stderr, fn->
        Mix.Tasks.Exfmt.run([])
      end)
      assert io =~ "--check"
    end

    test "file path" do
      io = capture_io(fn->
        Mix.Tasks.Exfmt.run(["priv/examples/ok.ex"])
      end)
      assert io == ":ok\n"
    end

    test "STDIN to STDOUT" do
      io = capture_io(" :ok ", fn->
        Mix.Tasks.Exfmt.run(["--stdin"])
      end)
      assert io == ":ok\n"
    end
  end
end
