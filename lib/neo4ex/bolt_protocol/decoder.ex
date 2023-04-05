defmodule Neo4ex.BoltProtocol.Decoder do
  @moduledoc """
  Decoding from Bolt Structures to Elixir Structs
  """
  alias Neo4ex.Utils
  alias Neo4ex.PackStream.{Markers, Decoder}

  @spec decode(binary(), Version.version()) :: term()
  def decode(data, bolt_version) when is_binary(bolt_version) do
    bolt_version = Version.parse!(bolt_version)
    decode(data, bolt_version)
  end

  def decode(data, bolt_version) when is_binary(data) do
    Stream.unfold(data, fn
      # end of data
      <<>> -> nil
      d -> do_decode(d, bolt_version)
    end)
  end

  # build decode functions for every version for every structure
  __ENV__.file
  |> Path.dirname()
  |> Utils.expand_dir("structure")
  |> Enum.filter(fn module -> function_exported?(module, :get_tag, 0) end)
  |> Enum.flat_map(fn module ->
    module.version_requirement()
    |> Utils.list_valid_versions()
    |> Enum.map(fn vsn -> {module, vsn} end)
  end)
  |> Enum.map(fn {module, vsn} ->
    struct_tag = module.get_tag()
    struct_marker = Markers.get!(:struct)
    vsn = Macro.escape(vsn)

    defp do_decode(
           <<unquote(struct_marker)::4, fields_count::4, unquote(struct_tag), rest::binary>>,
           unquote(vsn)
         ) do
      {field_values_list, rest} =
        if fields_count == 0 do
          {[], rest}
        else
          Enum.map_reduce(1..fields_count, rest, fn _, d ->
            do_decode(d, unquote(vsn))
          end)
        end

      data = unquote(module).load(field_values_list, unquote(vsn))

      {data, rest}
    end
  end)

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
