defmodule Neo4ex.Utils do
  @moduledoc false

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

    byte_count = byte_size_for_integer(term_size, false)
    marker_index = if byte_count < 1, do: 0, else: ceil(byte_count)
    marker = markers_type |> Markers.get!() |> Enum.at(marker_index)

    # marker could be nibble or octet
    marker_bits = bit_size_for_integer(marker)
    # term_size can be from a nibble (if marker is a nibble) up to 4 bytes
    term_bits = bit_size_for_term_size(marker, markers_type)

    <<marker::size(marker_bits), term_size::size(term_bits)>>
  end

  def byte_size_for_integer(number, round? \\ true)

  def byte_size_for_integer(number, true) do
    number |> byte_size_for_integer(false) |> ceil()
  end

  def byte_size_for_integer(number, false) do
    number |> Integer.digits(16) |> length() |> Kernel./(2)
  end

  def bit_size_for_integer(number) do
    number |> Integer.digits(16) |> length() |> Kernel.*(4)
  end

  def bit_size_for_term_size(marker, markers_type) do
    # if consecutive markers repeat it means that the values encoded should fall into the bigger limit
    # this happens for BitStrings which have the same marker up to 255 bytes of data
    # while other types tend to have one more marker for small data up to 16 bytes
    [first_marker | _] = markers = markers_type |> Markers.get!() |> Enum.dedup()
    marker_index = Enum.find_index(markers, &(&1 == marker))
    first_marker_size = bit_size_for_integer(first_marker)
    # sometimes first marker is 4 bits, so we count 4,8,16,32
    # otherwise marker sizes are limited to 8,16,32
    Integer.pow(2, marker_index) * first_marker_size
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
    Enum.filter(Neo4ex.Connector.supported_versions(), fn ver ->
      Version.match?(ver, requirement)
    end)
  end
end
