defmodule CogitoTest do
  use ExUnit.Case
  doctest Cogito

  # WIP: tests
  test "json list" do
    json_parser = Cogito.Json.parser()
    assert Cogito.parse(json_parser, "[1, 2, 3]") == {:ok, [1, 2, 3]}
    assert Cogito.parse(json_parser, "[]") == {:ok, []}
    assert Cogito.parse(json_parser, "100]") == {:err, :expected_eos, "]"}
  end
end
