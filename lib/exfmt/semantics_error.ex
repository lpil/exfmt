defmodule Exfmt.SemanticsError do
  defexception [:message, :line]

  @type t :: %__MODULE__{message: String.t}

  def exception(_ \\ nil) do
    message = """

    The semantic meaning of the source code differs between
    the input and the formatted output! We are unable to
    continue as formatting may break your code.

    This is a bug in `exfmt`. 😢

    Please report this problem, including the input source
    code file if possible.

    https://github.com/lpil/exfmt/issues/new

    """
    %__MODULE__{message: message}
  end
end
