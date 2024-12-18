import Config

config :example_app, ExampleApp.Connector,
  hostname: "localhost",
  principal: "neo4j",
  credentials: "letmein",
  pool_size: 1

config :boltx, Bolt,
  uri: "bolt://localhost:7687",
  auth: [username: "neo4j", password: "letmein"],
  user_agent: "boltxTest/1",
  pool_size: 1,
  max_overflow: 0,
  prefix: :default,
  name: Boltx
