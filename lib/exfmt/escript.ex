defmodule Exfmt.Escript do
  @moduledoc false

  def main(argv) do
    {parsed, argv} = OptionParser.parse_head!(argv, strict: [max_width: :integer])
    max_width = Keyword.get(parsed, :max_width, Exfmt.default_max_width())
    Enum.each(argv, &format(&1, max_width))
  end

  defp format(file, max_width) do
    new_contents =
      file
      |> File.read!()
      |> Exfmt.format!(max_width)

    File.write!(file, new_contents)
  end
end
