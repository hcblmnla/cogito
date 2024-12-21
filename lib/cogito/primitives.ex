defmodule Cogito.Primitives do
  @moduledoc """
  A list of primitive parsers.

  ## Parsers

  * **`chars`**
  * **`not_chars`**
  * **`word`**
  * **`space`**
  * **`ws`**
  * **`digit`**
  * **`natural`**
  * **`integer`**
  * **`float`**
  * **`letter`**
  * **`letter_or_digit`**
  * **`identifier`**
  * **`wrapped`**
  * **`iterable`**

  """

  import Cogito.Combinators

  defp codes(string) do
    string
    |> String.codepoints()
    |> Enum.map(fn <<code>> -> code end)
  end

  def chars(codes) when is_list(codes), do: char(&(&1 in codes))

  def chars(string) when is_bitstring(string) do
    string
    |> codes()
    |> chars()
  end

  def chars(range), do: range |> Enum.to_list() |> chars()

  def not_chars(string), do: char(&(&1 not in codes(string)))

  def word(string) do
    string
    |> codes()
    |> Enum.map(&char/1)
    |> seq()
  end

  def space, do: chars([?\s, ?\t, ?\n, ?\r, ?\v])

  def ws, do: space() |> star() |> ignore()

  def digit, do: chars(?0..?9)

  def natural, do: digit() |> plus()

  defp sign, do: chars("+-") |> optional()

  defp parse_number(parser) do
    fn string ->
      case parser.(string) do
        {parsed, _} -> parsed
        err -> err
      end
    end
  end

  def integer do
    [
      sign(),
      natural()
    ]
    |> seq()
    |> join()
    |> map(parse_number(&Integer.parse/1))
  end

  def float do
    [
      [
        sign(),
        natural()
      ]
      |> seq(),
      [
        char(?.),
        digit() |> star()
      ]
      |> seq()
      |> optional()
    ]
    |> fseq(&List.flatten/1)
    |> join()
    |> map(parse_number(&Float.parse/1))
  end

  def letter, do: Enum.concat(?a..?z, ?A..?Z) |> chars()

  def letter_or_digit, do: letter() |> either(digit())

  def identifier do
    [
      letter(),
      letter_or_digit() |> star()
    ]
    |> seq()
    |> join()
  end

  def wrapped(parser, left, right) do
    [
      word(left),
      parser,
      word(right)
    ]
    |> nth(1)
  end

  def iterable(parser, left, right, delimiter) do
    [
      word(left),
      [
        ws(),
        parser,
        [
          ws(),
          word(delimiter),
          ws(),
          parser
        ]
        |> nth(1)
        |> star()
      ]
      |> fseq(fn [h, t] -> [h | t] end)
      |> optional(),
      ws(),
      word(right)
    ]
    |> nth(1)
    |> map(fn
      nil -> []
      it -> it
    end)
  end
end
