defmodule Cogito.Combinators do
  alias Cogito.Lazy

  def identity(value) do
    fn input ->
      {:ok, value, input}
    end
  end

  defp bitchar(predicate, code, tail) do
    if predicate.(code) do
      {:ok, <<code>>, tail}
    else
      {:err, {:invalid_char, <<code>>, 1}}
    end
  end

  def char(predicate) when is_function(predicate, 1) do
    fn
      <<head, tail::bitstring>> -> bitchar(predicate, head, tail)
      "" -> {:err, :unexpected_eof}
      _input -> {:err, :invalid_input}
    end
  end

  def char(code) do
    char(fn ch -> ch == code end)
  end

  def map(parser, function) do
    fn input ->
      case parser.(input) do
        {:ok, parsed, tail} -> {:ok, function.(parsed), tail}
        err -> err
      end
    end
  end

  def concat(parser, parser2, function) do
    fn input ->
      case Lazy.get(parser).(input) do
        {:ok, head, tail} ->
          case Lazy.get(parser2).(tail) do
            {:ok, head2, tail2} ->
              {:ok, function.(head, head2), tail2}

            {:err, {reason, char, pos}} ->
              {:err, {reason, char, String.length(input) - String.length(tail) + pos}}

            err ->
              err
          end

        err ->
          err
      end
    end
  end

  defp error_pos({_, _, pos}), do: pos
  defp error_pos(_), do: -1

  def choice(parser, parser2) do
    fn input ->
      case Lazy.get(parser).(input) do
        {:err, reason} ->
          case Lazy.get(parser2).(input) do
            {:err, reason2} ->
              if error_pos(reason) > error_pos(reason2) do
                {:err, reason}
              else
                {:err, reason2}
              end

            ok ->
              ok
          end

        ok ->
          ok
      end
    end
  end

  defp some(_parser, "", acc) do
    {:ok, Enum.reverse(acc), ""}
  end

  defp some(parser, input, acc) do
    case parser.(input) do
      {:ok, parsed, tail} -> some(parser, tail, [parsed | acc])
      _err -> {:ok, Enum.reverse(acc), input}
    end
  end

  def some(parser) do
    fn input ->
      some(parser, input, [])
    end
  end

  def eos(parser) do
    fn input ->
      case parser.(input) do
        {:ok, parsed, ""} -> {:ok, parsed}
        {:ok, _, tail} -> {:err, :expected_eof, tail}
        err -> err
      end
    end
  end

  def ignore(parser), do: map(parser, fn _ -> :ignore end)

  def sequence(parsers) do
    parsers
    |> Enum.reverse()
    |> Enum.reduce(identity([]), fn parser, acc ->
      concat(parser, acc, fn parser, acc ->
        if parser == :ignore do
          acc
        else
          [parser | acc]
        end
      end)
    end)
  end

  def sequence(parsers, function), do: map(sequence(parsers), function)

  def nth(parsers, n), do: sequence(parsers, &Enum.at(&1, n))

  def choice(parsers), do: Enum.reduce(parsers, &choice/2)

  def optional(parser), do: choice(parser, identity(nil))

  def repeat(parser), do: concat(parser, some(parser), &[&1 | &2])

  def repeat(parser, n), do: sequence(List.duplicate(parser, n))

  def join(parser), do: map(parser, &Enum.join/1)
end
