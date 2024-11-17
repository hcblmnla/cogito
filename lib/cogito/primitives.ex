defmodule Cogito.Primitives do
  import Cogito.Combinators

  @quote_char ?"

  def include(codes) when is_list(codes) do
    char(fn ch -> ch in codes end)
  end

  def include(string) when is_bitstring(string) do
    string
    |> String.codepoints()
    |> Enum.map(fn <<code>> -> code end)
    |> include()
  end

  def include(range) do
    Enum.to_list(range) |> include()
  end

  def exclude(codes) when is_list(codes) do
    char(fn ch -> ch not in codes end)
  end

  # NOTE: copy-paste
  def string(string) do
    string
    |> String.codepoints()
    |> Enum.map(fn <<code>> -> code end)
    |> Enum.map(&char/1)
    |> sequence()
  end

  def space() do
    include([?\s, ?\t, ?\n, ?\r, ?\v])
  end

  def ws() do
    space()
    |> some()
    |> ignore()
  end

  def digit() do
    include(?0..?9)
  end

  def digits() do
    digit() |> repeat()
  end

  defp sign() do
    include("+-") |> optional()
  end

  defp parse_numeric(parser) do
    fn string ->
      case parser.(string) do
        {parsed, _} -> parsed
        err -> err
      end
    end
  end

  def integer() do
    [
      sign(),
      digits()
    ]
    |> sequence()
    |> join()
    |> map(parse_numeric(&Integer.parse/1))
  end

  def float() do
    [
      [
        sign(),
        digits()
      ]
      |> sequence(),
      [
        char(?.),
        digit() |> repeat()
      ]
      |> sequence()
      |> optional()
    ]
    |> sequence()
    |> join()
    |> map(parse_numeric(&Float.parse/1))
  end

  def string() do
    [
      char(@quote_char),
      exclude([@quote_char]) |> some() |> join(),
      char(@quote_char)
    ]
    |> nth(1)
  end

  def letter() do
    Enum.concat(?a..?z, ?A..?Z) |> include()
  end

  def letter_or_digit() do
    letter() |> choice(digit())
  end

  def identifier() do
    [
      letter(),
      letter_or_digit() |> some()
    ]
    |> sequence()
    |> join()
  end

  def null() do
    string("null") |> map(fn _ -> nil end)
  end
end
