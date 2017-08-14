defmodule Exfmt.Context do
  alias Exfmt.Ast.Infix
  require Infix

  @type stack_layer :: atom
  @type t :: %__MODULE__{stack: [stack_layer]}

  defstruct stack: []

  @doc """
  Create a new Context.

  """
  @spec new() :: t
  def new do
    %__MODULE__{}
  end

  @valid_layers ~W(list call keyword access negative sigil spec_lhs spec_rhs
                   tuple module_attribute map fn & do last_arg chain_call
                   struct_name <<>>)a ++ Infix.infix_ops

  @doc """
  Push a new value onto the stack, signifying another layer in the code.

      iex> new().stack
      []

      iex> ctx = new() |> push_stack(:call)
      ...> ctx.stack
      [:call]

      iex> ctx = new() |> push_stack(:call) |> push_stack(:list)
      ...> ctx.stack
      [:list, :call]

  """
  @spec push_stack(t, stack_layer) :: t
  def push_stack(ctx, value) when value in @valid_layers do
    %{ctx | stack: [value | ctx.stack]}
  end

  def stack_contains?(ctx, value) do
    Enum.member?(ctx.stack, value)
  end
end
