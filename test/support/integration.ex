defmodule Support.Integration do
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      require unquote(__MODULE__)
    end
  end

  defmacro src ~> expected do
    quote bind_quoted: binding() do
      {:ok, output} = Exfmt.unsafe_format(src, 40)
      assert output == expected
    end
  end
end
