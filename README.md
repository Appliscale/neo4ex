# Neo4Ex

Simple but powerful library that aims to add Ecto-like support for graph databases in Elixir.  

The goal here is to provide users with friendly API that allows quick development of advanced applications which could benefit from using graph database.

Do you need graph database? You may find some answers [here](https://neo4j.com/why-graph-databases/) and [here](https://memgraph.com/blog/graph-database-vs-relational-database).

Most popular engine for those is Neo4j thus this library focuses on providing full support for it, but there are more services, like [Memgraph](https://memgraph.com) or [Amazon Neptune](https://aws.amazon.com/neptune/). All of them share similar functionalities and are based on the same network protocol (Bolt) and query language (Cypher) so it's easy to switch between them.

Currently only simple quering using raw Cypher queries is implemented, but there are few items on the Roadmap.

## Installation

The package can be installed by adding `neo4ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:neo4ex, "~> 0.1.0"}
  ]
end
```

## Roadmap

- [ ] Implement Database driver using latest Bolt Protocol (v4+)  
- [ ] Add support for Neo4j Routing & Clustering  
- [ ] Build simple DSL for Cypher query language  
- [ ] Add support for mapping Nodes & Relationships to any struct