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

    test "check with correctly formatted code" do
      result = Exfmt.Cli.run(["--check", "priv/examples/ok.ex"])
      assert result.exit_code == 0
      assert result.stdout == nil
    end

    test "check with incorrectly formatted code" do
      result = Exfmt.Cli.run(["--check", "priv/examples/format_me.ex"])
      assert result.exit_code == 1
      assert result.stdout == nil
    end

    test "stdin check with correctly formatted code" do
      provide_stdin("[1, 2, 3]\n")
      result = Exfmt.Cli.run(["--check", "--stdin"])
      assert result.exit_code == 0
      assert result.stdout == nil
    end

    test "stdin check with incorrectly formatted code" do
      provide_stdin("[1,\n2]\n")
      result = Exfmt.Cli.run(["--check", "--stdin"])
      assert result.exit_code == 1
      assert result.stdout == nil
    end

    test "check stdin with syntax error" do
      provide_stdin(" - , = ")
      result = Exfmt.Cli.run(["--stdin", "--check"])
      assert result.exit_code == 1
      assert result.stderr =~ "Error: syntax error before"
    end

    test "maxwidth switch" do
      result = Exfmt.Cli.run(["--maxwidth", "40", "priv/examples/ok.ex"])
      assert result.stdout == ":ok\n"
    end
  end

  def provide_stdin(string) do
    {:ok, fake_stdin} = StringIO.open(string)
    Process.group_leader(self(), fake_stdin)
  end
end
