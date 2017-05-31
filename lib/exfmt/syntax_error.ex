defmodule Exfmt.SyntaxError do
  defexception [:message, :line]

  @type t :: %__MODULE__{line: non_neg_integer, message: String.t}

  def exception({line, m1, m2}) do
    %__MODULE__{line: line, message: "Error: " <> m1 <> m2}
  end

  def exception(message, line) do
    %__MODULE__{line: line, message: "Error: " <> message}
  end
end
