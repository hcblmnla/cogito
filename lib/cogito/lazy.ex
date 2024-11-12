defmodule Cogito.Lazy do
  def get(function) when is_function(function, 0) do
    function.()
  end

  def get(value), do: value
end
