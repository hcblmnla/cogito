defmodule CogitoTest do
  use ExUnit.Case
  doctest Cogito

  # WIP: tests
  test "empty json list" do
    assert Cogito.parse_json("[]") == {:ok, []}
  end
end
