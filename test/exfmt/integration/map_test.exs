defmodule Exfmt.Integration.MapTest do
  use ExUnit.Case
  import Support.Integration

  test "maps" do
    "%{}" ~> "%{}\n"
    "%{a: 1}" ~> "%{a: 1}\n"
    "%{:a => 1}" ~> "%{a: 1}\n"
    "%{1 => 1}" ~> "%{1 => 1}\n"
    "%{1 => 1, 2 => 2}" ~> "%{1 => 1, 2 => 2}\n"
  end

  test "map upsert %{map | key: value}" do
    "%{map | key: value}" ~> "%{map | key: value}\n"
  end

  test "chained map get" do
    assert_format "map.key.another.a_third\n"
  end

  test "qualified call into map get" do
    assert_format "Map.new.key\n"
  end

  test "structs" do
    assert_format "%Person{}\n"
    assert_format "%Person{age: 1}\n"
    "%Person{timmy | age: 1}" ~> "%Person{timmy | age: 1}\n"
    """
    %LongerNamePerson{timmy | name: "Timmy", age: 1}
    """ ~> """
    %LongerNamePerson{timmy |
                      name: "Timmy",
                      age: 1}
    """
    assert_format "%Inspect.Opts{}\n"
  end

  test "__MODULE__ structs" do
    assert_format "%__MODULE__.Person{}\n"
    assert_format "%__MODULE__{debug: true}\n"
  end

  test "variable type struct" do
    assert_format "%struct_type{}\n"
  end

  test "keys with spaces" do
    assert_format """
    %{"Implemented protocols": :ok}
    """
  end

  test "keys with dashes" do
    assert_format """
    %{"name-space": :ok}
    """
  end

  test "macro contents" do
    assert_format """
    %{unquote_splicing(spec)}
    """
  end
end
