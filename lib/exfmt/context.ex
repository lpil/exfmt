defmodule Exfmt.Context do
  @type t :: %__MODULE__{opts: Inspect.Opts.t}

  defstruct opts: %Inspect.Opts{}

  @spec new() :: t
  def new do
    %__MODULE__{}
  end
end
