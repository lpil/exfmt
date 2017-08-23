defmodule Exfmt.CliTest do
  use ExUnit.Case, async: true

  describe "Cli run" do
    test "check flag without path" do
      result = Exfmt.Cli.run(["--check"])
      assert result.stderr =~ "No input files given"
      assert result.stdout == nil
      assert result.exit_code == 1
    end

    test "path to unknown file" do
      result = Exfmt.Cli.run(["unknown-path-here"])
      assert result.stderr =~ "no such file or directory"
      assert result.stdout == nil
      assert result.exit_code == 1
    end

    test "file with valid syntax" do
      result = Exfmt.Cli.run(["priv/examples/ok.ex"])
      assert result.stdout == ":ok\n"
      assert result.stderr == nil
      assert result.exit_code == 0
    end

    test "file with syntax error" do
      result = Exfmt.Cli.run(["priv/examples/syntax_error.ex"])
      assert result.stdout == nil
      assert result.stderr =~ "Error: syntax error before"
      assert result.exit_code == 1
    end

    test "stdin with valid syntax" do
      provide_stdin(" :ok  ")
      result = Exfmt.Cli.run(["--stdin"])
      assert result.stdout == ":ok\n"
      assert result.stderr == nil
      assert result.exit_code == 0
    end

    test "stdin with syntax error" do
      provide_stdin(" - , = ")
      result = Exfmt.Cli.run(["--stdin"])
      assert result.stdout == nil
      assert result.stderr =~ "Error: syntax error before"
      assert result.exit_code == 1
    end

    test "check with correctly formatted code" do
      result = Exfmt.Cli.run(["--check", "priv/examples/ok.ex"])
      assert result.stdout == nil
      assert result.stderr == nil
      assert result.exit_code == 0
    end

    test "check with incorrectly formatted code" do
      result = Exfmt.Cli.run(["--check", "priv/examples/format_me.ex"])
      assert result.stdout == nil
      assert result.stderr == nil
      assert result.exit_code == 1
    end

    test "stdin check with correctly formatted code" do
      provide_stdin("[1, 2, 3]\n")
      result = Exfmt.Cli.run(["--check", "--stdin"])
      assert result.stdout == nil
      assert result.stderr == nil
      assert result.exit_code == 0
    end

    test "stdin check with incorrectly formatted code" do
      provide_stdin("[1,\n2]\n")
      result = Exfmt.Cli.run(["--check", "--stdin"])
      assert result.stdout == nil
      assert result.stderr == nil
      assert result.exit_code == 1
    end

    test "check stdin with syntax error" do
      provide_stdin(" - , = ")
      result = Exfmt.Cli.run(["--stdin", "--check"])
      assert result.stdout == nil
      assert result.stderr =~ "Error: syntax error before"
      assert result.exit_code == 1
    end
  end

  def provide_stdin(string) do
    {:ok, fake_stdin} = StringIO.open(string)
    Process.group_leader(self(), fake_stdin)
  end
end
