defmodule Cogito.Json do
  import Cogito.Combinators
  import Cogito.Primitives

  require Cogito.Combinators

  defp iterable(left, parser, right) do
    [
      string(left),
      [
        ws(),
        parser,
        [
          ws(),
          string(","),
          ws(),
          parser
        ]
        |> nth(1)
        |> some()
      ]
      |> sequence(fn [h, t] -> [h | t] end)
      |> optional(),
      ws(),
      string(right)
    ]
    |> nth(1)
    |> map(fn
      nil -> []
      it -> it
    end)
  end

  defp array() do
    iterable("[", value() |> lazy(), "]")
  end

  defp entry() do
    [
      identifier(),
      ws(),
      char(?:) |> ignore(),
      ws(),
      value() |> lazy()
    ]
    |> sequence()
  end

  defp object() do
    iterable("{", entry(), "}")
    |> map(fn
      nil ->
        %{}

      entries ->
        entries
        |> Enum.reverse()
        |> Enum.reduce(%{}, fn [key, value], acc ->
          Map.put(acc, key, value)
        end)
    end)
  end

  defp value() do
    [
      null(),
      integer(),
      string(),
      array(),
      object()
    ]
    |> choice()
  end

  def parser() do
    [
      ws(),
      value(),
      ws()
    ]
    |> nth(0)
    |> eos()
  end
end
