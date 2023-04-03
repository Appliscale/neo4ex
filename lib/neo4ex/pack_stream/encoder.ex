defprotocol Neo4Ex.PackStream.Encoder do
  @moduledoc """
  Encoding Elixir types to PackStream data
  """

  @spec encode(term()) :: binary()
  def encode(term)
end

defimpl Neo4Ex.PackStream.Encoder, for: Integer do
  alias Neo4Ex.Utils
  alias Neo4Ex.PackStream.Markers

  def encode(number) do
    # get real size of number to retrieve MSB
    byte_count = Utils.byte_size_for_integer(number)
    bits = byte_count * 8

    # we read one more bit from the beginning of number and check if it matches MSB
    # if it doesn't then we have to add one byte to properly write number to PackStream
    # for small ints we follow the rule from documentation and when we detect it then we don't add any marker
    pack_byte_diff =
      case <<number::size(bits + 1)>> do
        <<1::1, 0xF::4, _::bitstring>> when bits == 8 -> -1
        <<0::2, _::bitstring>> when bits == 8 -> -1
        <<msb::1, msb::1, _::bitstring>> -> 0
        _ -> 1
      end

    if pack_byte_diff < 0 do
      <<number>>
    else
      marker_index =
        byte_count
        |> Kernel.+(pack_byte_diff)
        |> :math.log2()
        |> ceil()

      marker = @for |> Markers.get!() |> Enum.at(marker_index)
      byte_count = Integer.pow(2, marker_index)

      <<marker, number::size(byte_count * 8)>>
    end
  end
end

defimpl Neo4Ex.PackStream.Encoder, for: Float do
  alias Neo4Ex.PackStream.Markers

  def encode(term) do
    marker = Markers.get!(@for)
    <<marker, term::float>>
  end
end

defimpl Neo4Ex.PackStream.Encoder, for: BitString do
  alias Neo4Ex.Utils

  def encode(term) do
    markers_type = if is_binary(term) and String.printable?(term), do: String, else: BitString

    term
    |> byte_size()
    |> Utils.enumerable_header(markers_type)
    |> Kernel.<>(term)
  end
end

defimpl Neo4Ex.PackStream.Encoder, for: Atom do
  alias Neo4Ex.PackStream.{Encoder, Markers}

  # for nil and boolean we just return a marker
  def encode(term) when is_boolean(term) or is_nil(term), do: <<Markers.get!(term)>>

  def encode(term) do
    term
    |> to_string()
    |> Encoder.encode()
  end
end

defimpl Neo4Ex.PackStream.Encoder, for: List do
  alias Neo4Ex.Utils

  # PackStream only informs that the List starts
  # it can't encode its items since those can be ANY type (some of them may need Bolt version information to be encoded)
  def encode(term) do
    term
    |> length()
    |> Utils.enumerable_header(@for)
  end
end

defimpl Neo4Ex.PackStream.Encoder, for: Map do
  alias Neo4Ex.Utils

  # PackStream only informs that the Map starts
  # it can't encode its items since those can be ANY type (some of them may need Bolt version information to be encoded)
  def encode(term) do
    term
    |> Map.keys()
    |> length()
    |> Utils.enumerable_header(@for)
  end
end
