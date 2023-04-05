defprotocol Neo4ex.BoltProtocol.Encoder do
  @moduledoc """
  Encoding to Bolt Structures
  """

  @spec encode(term(), Version.version()) :: binary()
  def encode(term, bolt_version)
end

defimpl Neo4ex.BoltProtocol.Encoder, for: List do
  alias Neo4ex.Utils
  alias Neo4ex.PackStream.Encoder
  alias Neo4ex.BoltProtocol.Encoder, as: BoltEncoder

  def encode(term, bolt_version) do
    encoded_data =
      Enum.reduce(term, <<>>, fn
        term, binary ->
          data =
            case Utils.choose_encoder(term) do
              BoltEncoder -> BoltEncoder.encode(term, bolt_version)
              _ -> Encoder.encode(term)
            end

          binary <> data
      end)

    Encoder.encode(term) <> encoded_data
  end
end

defimpl Neo4ex.BoltProtocol.Encoder, for: Map do
  alias Neo4ex.Utils
  alias Neo4ex.PackStream.Encoder
  alias Neo4ex.BoltProtocol.Encoder, as: BoltEncoder

  def encode(term, bolt_version) do
    encoded_data =
      Enum.reduce(term, <<>>, fn
        {key, value}, binary ->
          data =
            case Utils.choose_encoder(value) do
              BoltEncoder -> BoltEncoder.encode(value, bolt_version)
              _ -> Encoder.encode(value)
            end

          # key is string so if that doesn't work then something is really wrong
          binary <> Encoder.encode(key) <> data
      end)

    Encoder.encode(term) <> encoded_data
  end
end
