defmodule Exfmt.Integration.MapTest do
  use ExUnit.Case
  import Support.Integration

  test "maps" do
    assert_format "%{}"
    assert_format "%{a: 1}"
    "%{:a => 1}" ~> "%{a: 1}"
    assert_format "%{1 => 1}"
    assert_format "%{1 => 1, 2 => 2}"
  end

  test "map upsert %{map | key: value}" do
    assert_format "%{map | key: value}"
  end

  test "chained map get" do
    assert_format "map.key.another.a_third"
  end

  test "qualified call into map get" do
    assert_format "Map.new.key"
  end

  test "structs" do
    assert_format "%Person{}"
    assert_format "%Person{age: 1}"
    assert_format "%Person{timmy | age: 1}"
    """
    %LongerNamePerson{timmy | name: "Timmy", age: 1}
    """ ~> """
    %LongerNamePerson{timmy |
                      name: "Timmy",
                      age: 1}
    """
    assert_format "%Inspect.Opts{}"
  end

  test "__MODULE__ structs" do
    assert_format "%__MODULE__.Person{}"
    assert_format "%__MODULE__{debug: true}"
  end

  test "variable type struct" do
    assert_format "%struct_type{}"
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

  test "update of map from function" do
    assert_format """
    %{zero(0) | rank: 1}
    """
  end
end
