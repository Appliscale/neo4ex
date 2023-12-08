import Config

config :neo4ex, Neo4ex.Neo4jConnection,
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true

config :neo4ex, Neo4ex.Connector.Socket, transport_module: Neo4ex.Connector.SocketMock
