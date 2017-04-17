defmodule Exfmt do
  @moduledoc """
  Turning code into code, hopefully without breaking anything.
  """

  alias Exfmt.{AST, Context}

  def format(source, max_width \\ 100) do
    {:ok, tree} = Code.string_to_quoted(source)
    tree
    |> AST.to_algebra(Context.new)
    |> Inspect.Algebra.format(max_width)
    |> IO.chardata_to_string()
    |> (& &1 <> "\n").()
  end
end
