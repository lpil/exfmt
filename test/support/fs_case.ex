defmodule Exfmt.FsCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Exfmt.FsCase
    end
  end

  def project_root do
    Path.expand("../..", __DIR__)
  end

  def tmp_path do
    Path.join(project_root(), "tmp")
  end

  def tmp_path(extension) do
    Path.join(tmp_path(), to_string(extension))
  end

  def in_tmp(which, function) do
    path = tmp_path(which)
    File.rm_rf!(path)
    File.mkdir_p!(path)
    File.cd!(path, function)
  end

  defmacro test_in_tmp(message, var \\ quote do _ end, contents) do
    name = "#{Path.relative_to(__CALLER__.file, project_root())}:#{__CALLER__.line}"

    quote do
      test unquote(message), unquote(var) do
        in_tmp unquote(name), fn ->
          unquote(contents)
        end
      end
    end
  end
end
