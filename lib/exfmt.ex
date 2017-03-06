defmodule Exfmt do
  @moduledoc """
  Turning code into code, hopefully without breaking anything.
  """

  alias Exfmt.{AST, Context}

  def format(source) do
    {:ok, tree} = Code.string_to_quoted(source)
    tree
    |> AST.to_algebra(Context.new)
    |> Inspect.Algebra.format(80)
    |> IO.chardata_to_string()
  end
end

defmodule Exfmt.Context do
  @type t :: nil

  @spec new() :: t
  def new do
    nil
  end
end

defmodule Exfmt.AST do
  alias Exfmt.Context
  alias Inspect.Algebra

  require Algebra
  import Algebra

  @spec to_algebra(Macro.t, Context.t) :: Algebra.t
  def to_algebra(ast, context \\ nil)


  def to_algebra({:-, _, [number]}, _context) when is_number(number) do
    concat("-", to_string(number))
  end

  def to_algebra(number, _context) when is_number(number) do
    to_string(number)
  end
end
