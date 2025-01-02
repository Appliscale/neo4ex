defmodule Neo4ex.PackStream.DecoderBuilder do
  @moduledoc false

  alias Neo4ex.Utils
  alias Neo4ex.PackStream.Markers

  defmacro register_decoder(type, data_var, do: block) do
    type = Macro.expand(type, __ENV__)

    type
    |> Markers.get!()
    |> List.wrap()
    # if consecutive markers repeat it means that the values encoded should fall into the bigger limit
    # this happens for BitStrings which have the same marker up to 255 bytes of data and we have to remove repeating markers to get proper index
    # while other types tend to have one more marker for small data up to 16 bytes
    |> Enum.dedup()
    |> Enum.with_index(fn element, index ->
      {element, Utils.bit_size_for_term_size(index, type)}
    end)
    |> Enum.map(&build_decode_fn(&1, data_var, block))
  end

  defp build_decode_fn({marker_value, data_size}, data_var, block) do
    marker_size = Utils.count_bits(marker_value)

    data_var =
      Macro.prewalk(data_var, fn
        # inject size of data in places where size has placeholder
        {:size, meta, [{:_, _, _}]} -> {:size, meta, [data_size]}
        ast -> ast
      end)

    quote do
      defp do_decode(
             <<unquote(marker_value)::size(unquote(marker_size)), unquote(data_var)::bitstring>>
           ) do
        unquote(block)
      end
    end
  end
end
