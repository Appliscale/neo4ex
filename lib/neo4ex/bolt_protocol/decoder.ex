defmodule Neo4Ex.BoltProtocol.Decoder do
  @moduledoc """
  Decoding from Bolt Structures to Elixir Structs
  """
  alias Neo4Ex.PackStream.{Markers, Decoder}
  alias Neo4Ex.BoltProtocol.StructureRegistry

  @struct_marker Markers.get!(:struct)

  @spec decode(binary(), Version.version()) :: term()
  def decode(data, bolt_version) when is_binary(data) do
    Stream.unfold(data, fn
      # end of data
      <<>> -> nil
      d -> do_decode(d, bolt_version)
    end)
  end

  # if it's struct then we do lookup by Protocol
  defp do_decode(
         <<@struct_marker::4, fields_count::4, struct_tag, rest::binary>>,
         bolt_version
       ) do
    with(
      {:consolidated, impls} <- StructureRegistry.__protocol__(:impls),
      struct when is_atom(struct) <-
        Enum.find(impls, fn module ->
          module |> struct() |> StructureRegistry.get_tag(bolt_version) == struct_tag
        end)
    ) do
      {field_values_list, rest} =
        if fields_count == 0 do
          {[], rest}
        else
          Enum.map_reduce(1..fields_count, rest, fn _, d ->
            do_decode(d, bolt_version)
          end)
        end

      data = struct.load(field_values_list, bolt_version)

      {data, rest}
    end
  end

  # otherwise it can be handled by PackStream decoder
  defp do_decode(data, bolt_version) do
    case Decoder.decode(data) do
      {%{size: 0}, rest} -> {%{}, rest}
      {%{size: map_size}, rest} -> build_map(map_size, rest, bolt_version)
      {l, rest} when is_list(l) -> build_list(l, rest, bolt_version)
      other -> other
    end
  end

  defp build_list(empty_list, binary, bolt_version) do
    Enum.map_reduce(empty_list, binary, fn _, d -> do_decode(d, bolt_version) end)
  end

  defp build_map(map_size, binary, bolt_version) do
    {data, rest} =
      Enum.map_reduce(1..map_size, binary, fn _, d ->
        {key, d} = do_decode(d, bolt_version)
        {value, d} = do_decode(d, bolt_version)
        {{key, value}, d}
      end)

    {Enum.into(data, %{}), rest}
  end
end
