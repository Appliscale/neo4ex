defmodule Neo4ex.Utils do
  @moduledoc false

  import Neo4ex.Connector, only: [supported_versions: 0]
  import Bitwise

  alias Neo4ex.BoltProtocol

  alias Neo4ex.PackStream
  alias Neo4ex.PackStream.Markers
  alias Neo4ex.PackStream.Exceptions

  @lib_dir File.cwd!() |> Path.join("lib")
  # 32-bit signed integer
  @max_enumerable_size 0x7FFFFFFF

  # binaries and lists share similar logic
  def enumerable_header(term_size, markers_type) do
    if term_size > @max_enumerable_size do
      raise Exceptions.SizeError
    end

    bit_count = count_bits(term_size)
    marker_index = if bit_count <= 4, do: 0, else: bit_count >>> 2

    markers = Markers.get!(markers_type)
    marker = Enum.at(markers, marker_index)

    # if consecutive markers repeat it means that the values encoded should fall into the bigger limit
    # this happens for BitStrings which have the same marker up to 255 bytes of data and we have to remove repeating markers to get proper index
    # while other types tend to have one more marker for small data up to 16 bytes
    marker_index = markers |> Enum.dedup() |> Enum.find_index(&(&1 == marker))

    # marker could be nibble or octet
    marker_bits = count_bits(marker)
    # term_size can be from a nibble (if marker is a nibble) up to 4 bytes
    term_bits = bit_size_for_term_size(marker_index, markers_type)

    <<marker::size(marker_bits), term_size::size(term_bits)>>
  end

  def bit_size_for_term_size(marker_index, markers_type) do
    [first_marker | _] = Markers.get!(markers_type) |> List.wrap()
    # sometimes first marker is 4 bits, so we count 4,8,16,32
    # otherwise marker sizes are limited to 8,16,32
    count_bits(first_marker) <<< marker_index
  end

  def choose_encoder(term) do
    cond do
      BoltProtocol.Encoder.impl_for(term) -> BoltProtocol.Encoder
      PackStream.Encoder.impl_for(term) -> PackStream.Encoder
      true -> nil
    end
  end

  def require_modules(base, file) do
    path = Path.join(base, file)

    case File.dir?(path) do
      true ->
        path
        |> File.ls!()
        |> Enum.flat_map(fn sub -> require_modules(path, sub) end)

      false ->
        file =
          file
          |> Path.rootname(".ex")
          |> Macro.camelize()

        base
        |> Path.relative_to(@lib_dir)
        |> Macro.camelize()
        |> Module.concat(file)
        |> Code.ensure_compiled!()
        |> List.wrap()
    end
  end

  def list_valid_versions(requirement) do
    Enum.filter(supported_versions(), fn ver ->
      Version.match?(ver, requirement)
    end)
  end

  def power_of_two?(x), do: (x &&& x - 1) == 0

  def count_bits(x, sign? \\ false)
  def count_bits(x, false) when x >= 0, do: count_bits_unsigned(x)

  # Calculate the bit length for the absolute value, then add 1 for the sign bit
  def count_bits(x, true) do
    bit_length = x |> abs() |> count_bits_unsigned()

    # make sure the sign is preserved in this comparison
    if x == -1 <<< (bit_length - 1) do
      bit_length
    else
      bit_length + 1
    end
  end

  # Count bits for unsigned numbers
  defp count_bits_unsigned(0), do: 0
  defp count_bits_unsigned(x), do: 1 + count_bits_unsigned(x >>> 1)
end
