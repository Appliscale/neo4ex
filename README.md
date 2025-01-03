# Neo4ex

Simple but powerful library that aims to add Ecto-like support for graph databases in Elixir.  

The goal here is to provide users with friendly API that allows quick development of advanced applications which could benefit from using graph database.

Do you need graph database? You may find some answers [here](https://neo4j.com/why-graph-databases/) and [here](https://memgraph.com/blog/graph-database-vs-relational-database).

Most popular engine for those is Neo4j thus this library focuses on providing full support for it, but there are more services, like [Memgraph](https://memgraph.com) or [Amazon Neptune](https://aws.amazon.com/neptune/). All of them share similar functionalities and are based on the same network protocol (Bolt) and query language (Cypher) so it's easy to switch between them.

Currently only simple quering using raw Cypher queries is implemented, but there are few items on the Roadmap.

## Existing libraries

There were already few attempts to write a driver for Bolt protocol but all of them seem to be clumsy in terms of protocol logic - many things are "hardcoded" as in the docs instead of being thought out for the server's operation and coding a reusable solution. They are not taking advantage of Elixir structs, protocols and behaviours to provide robust extensibility.  
Secondly, those libs are just a driver and this library purpose is to provide complete user experience when interacting with the DB.  
This should be solved by building Ecto-like support for the Cypher query language.  

At this point, it's worth noting that this library may not be faster than `bolt_sips` or `boltx` due to greater usage of Protocols and structs.  
You can modify tasks from `example_app` to benchmark those on your data.

## Installation

The package can be installed by adding `neo4ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:neo4ex, "~> 0.1.0"}
  ]
end
```

## Usage

Configuration is very similar to the Ecto, so the ones familiar with it should have no problem understanding it.

1. Create module that will act as a connection process

    ```elixir
    defmodule MyApp.Neo4jConnection do
      use Neo4ex.Connector,
        otp_app: :my_app
    end
    ```

2. Define connection params in config

    ```elixir
    config :my_app, MyApp.Neo4jConnection,
      hostname: "localhost", # required
      port: 7687, # default
      principal: "neo4j", # optional
      credentials: "neo4j", # optional
    ```

3. Add `MyApp.Neo4jConnection` to your `application.ex`

    ```elixir
    children = [
      # Starts the database connection pool
      MyApp.Neo4jConnection
    ]
    ```

4. Query database using `MyApp.Neo4jConnection.run/1` and `Neo4ex.Cypher.Query`

    ```elixir
    MyApp.Neo4jConnection.run(
      %Neo4ex.Cypher.Query{query: "MATCH (n) RETURN n"}
    )
    ```

Ecto-like Cypher DSL is one of the things that are on the Roadmap

## Example data
This repository contains small app that starts Neo4ex connection and Neo4j server.
After running `docker-compose up` go to the web interface (`http://localhost:7474`) and execute import command:
```
LOAD CSV WITH HEADERS FROM 'file:///example_data/customers-10000.csv' AS row
CALL apoc.create.node(['Elixir.ExampleApp.Schema.Customer'], row) YIELD node
RETURN node

LOAD CSV WITH HEADERS FROM 'file:///example_data/organizations-10000.csv' AS row
CALL apoc.create.node(['Elixir.ExampleApp.Schema.Organization'], row) YIELD node
RETURN node

MATCH (c:`Elixir.ExampleApp.Schema.Customer`), (o:`Elixir.ExampleApp.Schema.Organization`) WHERE c.country = o.country
MERGE (c)-[:CUSTOMER_OF]->(o)
```
After that you can start application located in `example_app` and play with the data.

## Roadmap

- [x] Implement Database driver using latest Bolt Protocol (v4+)  
- [ ] Add support for Neo4j Routing & Clustering  
- [ ] Build simple DSL for Cypher query language  
- [ ] Add support for mapping Nodes & Relationships to any struct