defmodule Cogito.Combinators do
  @moduledoc """
  A list of basic combinators.

  ## Combinators

  * **`identity`**
  * **`char`**
  * **`map`**
  * **`concat`**
  * **`either`**
  * **`star`**
  * **`plus`**
  * **`seq`**
  * **`fseq`**
  * **`nth`**
  * **`repeat`**
  * **`choice`**
  * **`optional`**
  * **`join`**
  * **`ignore`**
  * **`eos`**
  * **`lazy`**

  """

  def identity(value), do: &{:ok, value, &1}

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
      "" -> {:err, :unexpected_eos}
      _input -> {:err, :invalid_input}
    end
  end

  def char(code), do: char(&(&1 == code))

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
      case parser.(input) do
        {:ok, head, tail} ->
          case parser2.(tail) do
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

  def either(parser, parser2) do
    fn input ->
      case parser.(input) do
        {:err, reason} ->
          case parser2.(input) do
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

  defp do_star(_parser, "", acc), do: {:ok, Enum.reverse(acc), ""}

  defp do_star(parser, input, acc) do
    case parser.(input) do
      {:ok, parsed, tail} -> do_star(parser, tail, [parsed | acc])
      _err -> {:ok, Enum.reverse(acc), input}
    end
  end

  def star(parser), do: &do_star(parser, &1, [])

  def plus(parser), do: concat(parser, star(parser), &[&1 | &2])

  def seq(parsers) do
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

  def fseq(parsers, function), do: map(seq(parsers), function)

  def nth(parsers, n), do: fseq(parsers, &Enum.at(&1, n))

  def repeat(parser, n), do: seq(List.duplicate(parser, n))

  def choice(parsers), do: Enum.reduce(parsers, &either/2)

  def optional(parser), do: either(parser, identity(nil))

  def join(parser), do: map(parser, &Enum.join/1)

  def ignore(parser), do: map(parser, fn _ -> :ignore end)

  def eos(parser) do
    fn input ->
      case parser.(input) do
        {:ok, parsed, ""} -> {:ok, parsed}
        {:ok, _, tail} -> {:err, {:expected_eos, tail}}
        err -> err
      end
    end
  end

  defmacro lazy(parser) do
    quote do
      fn input ->
        unquote(parser).(input)
      end
    end
  end
end
