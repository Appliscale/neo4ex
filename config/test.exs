import Config

config :neo4ex, Neo4Ex.Connector,
  hostname: "localhost",
  principal: "neo4j",
  credentials: "letmein",
  pool_size: 1,
  show_sensitive_data_on_connection_error: true

config :neo4ex, Neo4Ex.Connector.Socket, transport_module: Neo4Ex.Connector.SocketMock
