defmodule Semantic.ExfmtProjectTest do
  use ExUnit.Case, async: true
  use Support.Semantic

  project_pattern = "./{test,lib}/**/*.ex{,s}"

  for path <- Path.wildcard(project_pattern) do
    test "semantics of #{path} after formatting" do
      assert_semantics_retained unquote(path)
    end
  end
end
