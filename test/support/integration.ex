defmodule Support.Integration do
  import ExUnit.Assertions

  def src ~> expected do
    assert {:ok, output} = Exfmt.unsafe_format(src, 40)
    assert output == expected
  end
end
