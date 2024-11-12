defmodule Cogito do
  alias Cogito.Json

  def parse_json(json) do
    Json.parser().(json)
  end
end
