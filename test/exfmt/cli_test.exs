defmodule Exfmt.CliTest do
  use ExUnit.Case, async: true

  describe "Cli run" do
    test "path to unknown file" do
      result = Exfmt.Cli.run(["unknown-path-here"])
      assert result.stderr =~ "no such file or directory"
      assert result.stderr =~ "unknown-path-here"
    end

    test "file with valid syntax" do
      result = Exfmt.Cli.run(["priv/examples/ok.ex"])
      assert result.stdout == ":ok\n"
    end

    test "file with syntax error" do
      result = Exfmt.Cli.run(["priv/examples/syntax_error.ex"])
      assert result.stderr =~ "Error: syntax error before"
    end

    test "stdin with valid syntax" do
      provide_stdin(" :ok  ")
      result = Exfmt.Cli.run(["--stdin"])
      assert result.stdout == ":ok\n"
    end

    test "stdin with syntax error" do
      provide_stdin(" - , = ")
      result = Exfmt.Cli.run(["--stdin"])
      assert result.stderr =~ "Error: syntax error before"
    end
  end

  def provide_stdin(string) do
    {:ok, fake_stdin} = StringIO.open(string)
    Process.group_leader(self(), fake_stdin)
  end
end
