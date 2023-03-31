defmodule Neo4Ex.Connector.Socket do
  @moduledoc """
  A default socket interface used to communicate to a Neo4j instance.
  Any other socket implementing the same interface can be used
  in place of this one. Actually, this module doesn't
  implement the interface on its own, it delegates calls to
  the gen_tcp (http://erlang.org/doc/man/gen_tcp.html)
  """

  # define behaviour that can be adopted by other module
  @callback connect(String.t(), integer(), list()) :: {:ok, port()}
  @callback send(port(), any()) :: :ok
  @callback recv(port(), integer()) :: {:ok, any()}
  @callback close(port()) :: :ok

  @transport_module Application.compile_env(:neo4ex, [__MODULE__, :transport_module], :gen_tcp)

  def connect(host, port, opts),
    do: @transport_module.connect(String.to_charlist(host), port, opts)

  defdelegate send(sock, package), to: @transport_module

  # DBConnection manages timeouts for us B)
  defdelegate recv(sock, length), to: @transport_module

  defdelegate close(sock), to: @transport_module

  @doc "Defines the state used by Protocol implementation"
  defstruct [:sock, bolt_version: "0.0.0"]

  @type t :: %__MODULE__{sock: port(), bolt_version: Version.version()}
end
