defprotocol Neo4ex.PackStream.Encoder do
  @moduledoc """
  Encoding Elixir types to PackStream data
  """

  @spec encode(term()) :: binary()
  def encode(term)
end

defimpl Neo4ex.PackStream.Encoder, for: Integer do
  import Bitwise

  alias Neo4ex.Utils
  alias Neo4ex.PackStream.Markers

  def encode(number) do
    # get real size of number to retrieve MSB
    byte_count = byte_size_for_integer(number)

    # for small ints we follow the rule from documentation and when we detect it then we don't add any marker
    tiny_int =
      case <<number::size(byte_count <<< 3)>> do
        <<0xF::4, _::4>> -> true
        <<0::1, _::7>> -> true
        _ -> false
      end

    if tiny_int do
      <<number>>
    else
      marker_index = ceil_log2(byte_count)
      marker = @for |> Markers.get!() |> Enum.at(marker_index)
      byte_count = 1 <<< marker_index

      <<marker, number::size(byte_count * 8)>>
    end
  end

  defp byte_size_for_integer(0), do: 1

  defp byte_size_for_integer(number) do
    ((Utils.count_bits(number, true) - 1) >>> 3) + 1
  end

  defp ceil_log2(x) do
    bit_length = Utils.count_bits(x)

    # Check if x is already a power of 2
    if Utils.power_of_two?(x) do
      bit_length - 1
    else
      bit_length
    end
  end
end

defimpl Neo4ex.PackStream.Encoder, for: Float do
  alias Neo4ex.PackStream.Markers

  def encode(term) do
    marker = Markers.get!(@for)
    <<marker, term::float>>
  end
end

defimpl Neo4ex.PackStream.Encoder, for: BitString do
  alias Neo4ex.Utils

  def encode(term) do
    markers_type = if is_binary(term) and String.printable?(term), do: String, else: BitString

    term
    |> byte_size()
    |> Utils.enumerable_header(markers_type)
    |> Kernel.<>(term)
  end
end

defimpl Neo4ex.PackStream.Encoder, for: Atom do
  alias Neo4ex.PackStream.{Encoder, Markers}

  # for nil and boolean we just return a marker
  def encode(term) when is_boolean(term) or is_nil(term), do: <<Markers.get!(term)>>

  def encode(term) do
    term
    |> to_string()
    |> Encoder.encode()
  end
end

defimpl Neo4ex.PackStream.Encoder, for: List do
  alias Neo4ex.Utils

  # PackStream only informs that the List starts
  # it can't encode its items since those can be ANY type (some of them may need Bolt version information to be encoded)
  def encode(term) do
    term
    |> length()
    |> Utils.enumerable_header(@for)
  end
end

defimpl Neo4ex.PackStream.Encoder, for: Map do
  alias Neo4ex.Utils

  # PackStream only informs that the Map starts
  # it can't encode its items since those can be ANY type (some of them may need Bolt version information to be encoded)
  def encode(term) do
    term
    |> Map.keys()
    |> length()
    |> Utils.enumerable_header(@for)
  end
end
