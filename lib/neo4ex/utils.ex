defmodule Neo4Ex.Utils do
  @moduledoc false

  alias Neo4Ex.PackStream
  alias Neo4Ex.BoltProtocol

  # binaries and lists share similar logic
  def enumerable_header(term_size, markers) do
    byte_count = byte_size_for_integer(term_size, false)
    marker_index = if byte_count < 1, do: 0, else: ceil(byte_count)
    marker = Enum.at(markers, marker_index)
    marker_size = byte_size_for_integer(marker, false)

    # marker could be nibble or octet
    marker_bits = round(marker_size * 8)
    # term_size can be from a nibble (if marker is a nibble) up to 4 bytes
    term_bits = if marker_bits == 4, do: 4, else: byte_count |> ceil() |> Kernel.*(8)

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

  def choose_encoder(term) do
    cond do
      BoltProtocol.Encoder.impl_for(term) -> BoltProtocol.Encoder
      PackStream.Encoder.impl_for(term) -> PackStream.Encoder
      true -> nil
    end
  end
end
