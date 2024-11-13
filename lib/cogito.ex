defmodule Cogito do
  def parse(parser, input) do
    parser.(input)
  end
end
