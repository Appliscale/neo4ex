defmodule Neo4Ex.PackStream.Markers do
  @moduledoc """
  This module defines values of markers that PackStream uses to detect the type of data
  """
  alias Neo4Ex.PackStream.Exceptions

  @spec get!(term()) :: integer() | [integer()]
  def get!(term)

  def get!(nil), do: 0xC0
  def get!(false), do: 0xC2
  def get!(true), do: 0xC3
  def get!(Float), do: 0xC1
  def get!(Integer), do: [0xC8, 0xC9, 0xCA, 0xCB]
  # for small binary we have only high-order nibble and size is kept in low-order nibble
  def get!(String), do: [0x8, 0xD0, 0xD1, 0xD2]
  # special case for non-printable binaries,
  # there is no marker for small ones (16 bytes) so we return the same for first two
  def get!(BitString), do: [0xCC, 0xCC, 0xCD, 0xCE]
  def get!(List), do: [0x9, 0xD4, 0xD5, 0xD6]
  def get!(Map), do: [0xA, 0xD8, 0xD9, 0xDA]

  def get!(:struct), do: 0xB

  def get!(term), do: raise(Exceptions.MarkersError, term)
end
