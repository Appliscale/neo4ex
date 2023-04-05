import Config

config :neo4ex, Neo4ex.Connector,
  hostname: "localhost",
  principal: "neo4j",
  credentials: "letmein",
  pool_size: 1,
  show_sensitive_data_on_connection_error: true

config :neo4ex, Neo4ex.Connector.Socket, transport_module: Neo4ex.Connector.SocketMock
