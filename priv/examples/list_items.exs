defmodule ListItems do
  def nested_list do
    list = [:nested_one, :nested_two, :nested_three]
    [:top_level_one, :top_level_two, :top_level_two, list]
  end
end
