import Config

config :example_app, ExampleApp.Connector,
  hostname: "localhost",
  principal: "neo4j",
  credentials: "letmein",
  pool_size: 1

config :bolt_sips, Bolt,
  url: "bolt://localhost:7687",
  basic_auth: [username: "neo4j", password: "letmein"],
  pool_size: 1,
  max_overflow: 0
