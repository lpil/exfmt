defmodule Exfmt.Escript do
  def main(argv) do
    Mix.Tasks.Exfmt.run argv
  end
end
