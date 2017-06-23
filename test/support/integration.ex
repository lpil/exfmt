defmodule Support.Integration do
  import ExUnit.Assertions

  def source ~> expected do
    assert {:ok, output} = Exfmt.unsafe_format(source, 40)
    assert expected == output
  end

  def assert_format(expected) do
    assert {:ok, output} = Exfmt.unsafe_format(expected, 40)
    assert expected == output
  end
end
