defmodule Support.Semantic do
  @moduledoc """
  Utilies for checking whether Exfmt alters the semantic meaning
  when formatting a given string of code.

  """


  defmacro __using__(_) do
    quote do
      require unquote(__MODULE__)
      import unquote(__MODULE__)
    end
  end


  @doc """
  For a given string of source code, format it with Exfmt and
  compare the resulting AST to the original AST in order to
  detect whether the semantics of the code has changed.

  """
  defmacro assert_semantics_retained(source) do
    import ExUnit.Assertions, only: [assert: 1]
    quote bind_quoted: [source: source] do
      formatted = Exfmt.format!(source)
      assert macro_format(source) == macro_format(formatted)
    end
  end


  # DUPE: 120
  @doc """
  Convert source to AST and back again using `Macro.to_string`.
  This can be used to detect variations in semantic meaning.

  """
  def macro_format(source) do
    source
    |> Code.string_to_quoted!()
    |> Macro.to_string()
  end
end
