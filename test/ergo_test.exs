defmodule CogitoTest do
  use ExUnit.Case
  doctest Cogito

  defp checker_ok(parser) do
    fn input, parsed ->
      assert Cogito.parse(parser, input) == {:ok, parsed}
    end
  end

  defp checker_err(parser) do
    fn input ->
      case Cogito.parse(parser, input) do
        {:err, reason} -> IO.puts("Input: \"#{input}\", reason: #{inspect(reason)}")
        _ -> raise("Expected error: #{input}")
      end
    end
  end

  # TODO: json err and extract JsonTest module

  test "json values" do
    json_parser = Cogito.Json.parser()
    ok = checker_ok(json_parser)

    ok.("1", 1)
    ok.("100500", 100_500)
    ok.("-987321", -987_321)
    ok.("null", nil)

    ok.("\"abc\"", "abc")
    ok.("\"null\"", "null")
    ok.("\"Daniil Serov\"", "Daniil Serov")
  end

  test "json list" do
    json_parser = Cogito.Json.parser()
    ok = checker_ok(json_parser)

    ok.("[]", [])
    ok.("[1, 2, 3]", [1, 2, 3])
    ok.("[null]", [nil])
    ok.("[\"Abc\", -42, null, \"\", \"null\"]", ["Abc", -42, nil, "", "null"])

    ok.("[[], [[]]]", [[], [[]]])
    ok.("[[], [1], 2, [[3, [\" \"]]]]", [[], [1], 2, [[3, [" "]]]])
  end

  test "json object" do
    json_parser = Cogito.Json.parser()
    ok = checker_ok(json_parser)

    ok.("{}", %{})
    ok.("{abc: 1, d: null, s: \"abc\"}", %{"abc" => 1, "d" => nil, "s" => "abc"})

    ok.("{abc: {def: {xyz: {}}}, abc2: {n: 100}}", %{
      "abc" => %{"def" => %{"xyz" => %{}}},
      "abc2" => %{"n" => 100}
    })
  end

  test "json all" do
    json_parser = Cogito.Json.parser()
    ok = checker_ok(json_parser)

    ok.("[{a: [1, 2, 3]}]", [%{"a" => [1, 2, 3]}])
    ok.("[1, {a: \"hello\", b: [1, 2, 3]}, null]", [1, %{"a" => "hello", "b" => [1, 2, 3]}, nil])

    ok.("{employees: [{John: {age: 20, car: null}}, {Anna: {age: 23, car: \"Lada\"}}]}", %{
      "employees" => [
        %{"John" => %{"age" => 20, "car" => nil}},
        %{"Anna" => %{"age" => 23, "car" => "Lada"}}
      ]
    })
  end

  test "json ws" do
    json_parser = Cogito.Json.parser()
    ok = checker_ok(json_parser)

    ok.("    \n\t 100 \n\n", 100)
    ok.("  [ \t\t1,2,   3\n]", [1, 2, 3])
    ok.("[{},      \"abc\"]\n\n", [%{}, "abc"])
  end

  test "json err" do
    json_parser = Cogito.Json.parser()
    err = checker_err(json_parser)

    err.("")
    err.("[]]")
    err.("[null, nul]")
    err.("100.1")
    err.("1 2 3 4")
    err.("abc")

    err.("{a:[10, 11, 12]]}")
    err.("[100[")
    err.("[[~]]")
    err.("\"string\"~")

    err.("[1, {a: \"hello, b: [1, 2, 3]}, null]")
    err.("[1, {a: \"hello\", b: [1, 2, 3]} null]")
    err.("[1, {a: \"hello\", b: [1, 2, 3]}, null~")
  end
end
