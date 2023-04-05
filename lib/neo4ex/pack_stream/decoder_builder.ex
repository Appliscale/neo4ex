defmodule Neo4ex.PackStream.DecoderBuilder do
  @moduledoc false

  alias Neo4ex.Utils
  alias Neo4ex.PackStream.Markers

  defmacro register_decoder(type, marker_var, data_var, do: block) do
    type
    |> Macro.expand(__ENV__)
    |> Markers.get!()
    |> List.wrap()
    |> Enum.map(&build_decode_fn(&1, marker_var, data_var, block))
  end

  defp build_decode_fn(marker_value, marker_var, data_var, block) do
    marker_size = Utils.bit_size_for_integer(marker_value)

    quote do
      defp do_decode(
             <<unquote(marker_var)::size(unquote(marker_size)), unquote(data_var)::bitstring>>
           )
           when unquote(marker_var) == unquote(marker_value) do
        unquote(block)
      end
    end
  end
end
