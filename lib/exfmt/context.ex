defmodule Exfmt.Context do
  @type t :: %__MODULE__{opts: Inspect.Opts.t}

  defstruct opts: %Inspect.Opts{},
            stack: []

  @doc """
  Create a new Context.

  """
  @spec new() :: t
  def new do
    %__MODULE__{}
  end

  @doc """
  Push a new value onto the stack, signifying another layer in the code.

      iex> new().stack
      []

      iex> ctx = new() |> push_stack(:call)
      ...> ctx.stack
      [:call]

      iex> ctx = new() |> push_stack(:call) |> push_stack(:cast)
      ...> ctx.stack
      [:cast, :call]
  """
  @spec push_stack(t, term) :: t
  def push_stack(ctx, value) do
    call_ctx = %{ctx | stack: [value|ctx.stack]}
  end
end
