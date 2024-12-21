defmodule Cogito do
  @moduledoc """
  A module that parses a string.
  """

  def parse(parser, input) when is_function(parser, 1), do: parser.(input)
end
