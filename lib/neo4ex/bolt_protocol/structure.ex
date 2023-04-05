defmodule Neo4ex.BoltProtocol.Structure do
  @moduledoc """
  Provides some boilerplate for handling Bolt structures.
  """
  alias Neo4ex.BoltProtocol.Structure
  alias Neo4ex.BoltProtocol.Encoder, as: BoltEncoder
  alias Neo4ex.PackStream.Encoder
  alias Neo4ex.Utils

  @callback get_tag() :: integer()
  @callback version_requirement() :: Version.requirement()
  @callback load(list(any()), Version.version()) :: any()

  defmacro __using__(_) do
    quote do
      import Neo4ex.BoltProtocol.Structure
    end
  end

  defmacro embeded_structure(block) do
    fields_list = build_fields_list(block)
    struct = structure(fields_list)
    protocol = embedded_encoder_protocol(fields_list)
    [struct, protocol]
  end

  defmacro structure(tag, do: block) do
    fields_list = build_fields_list(block)
    struct = structure(fields_list)
    protocol = encoder_protocol(fields_list)
    helpers = behaviour(tag, fields_list)
    doc = gen_doc(tag, fields_list)

    [doc, struct, protocol, helpers]
  end

  @doc false
  def valid_field?({_, opts}, bolt_version) do
    requirement =
      opts
      |> Keyword.get(:version, "")

    Version.match?(bolt_version, requirement)
  end

  @doc false
  def encode({field, _}, struct, bolt_version) do
    term = Map.get(struct, field)

    case Utils.choose_encoder(term) do
      BoltEncoder -> BoltEncoder.encode(term, bolt_version)
      Encoder -> Encoder.encode(term)
      nil -> <<>>
    end
  end

  defp gen_doc(tag, fields_list) do
    field_str =
      quote bind_quoted: [fields_list: fields_list] do
        Enum.map_join(fields_list, "\n", fn {name, opts} ->
          field_str = "#{name}: #{inspect(opts[:default])}"

          if opts[:version] != Version.parse_requirement!(">= 0.0.0") do
            field_str <> " (version #{opts[:version]})"
          else
            field_str
          end
        end)
      end

    quote do
      @moduledoc """
      ### Tag: `0x#{Integer.to_string(unquote(tag), 16)}`
      ### Fields:
      ```plaintext
      #{unquote(field_str)}
      ```
      """
    end
  end

  defp build_fields_list(block) do
    block
    |> Macro.prewalk([], fn
      {:field, _, [name, opts]}, acc ->
        opts =
          Keyword.update(
            opts,
            :version,
            quote(do: Version.parse_requirement!(">= 0.0.0")),
            fn requirement ->
              requirement = Version.parse_requirement!(requirement)
              quote(do: unquote(Macro.escape(requirement)))
            end
          )

        {nil, [{name, opts} | acc]}

      other, acc ->
        {other, acc}
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  defp structure(fields_list) do
    struct_def = Enum.map(fields_list, fn {field, opts} -> {field, opts[:default]} end)

    quote do
      defstruct unquote(struct_def)
    end
  end

  defp behaviour(tag, fields_list) do
    quote location: :keep do
      @behaviour Structure

      def get_tag(), do: unquote(tag)

      # by default
      def version_requirement(), do: Version.parse_requirement!(">= 0.0.0")

      def load(fields_values, bolt_version) do
        attrs =
          unquote(fields_list)
          # pick fields that satisfy version requirement
          |> Enum.filter(&Structure.valid_field?(&1, bolt_version))
          |> Keyword.keys()
          |> Enum.zip(fields_values)
          |> Enum.into(%{})

        struct(__MODULE__, attrs)
      end

      defoverridable version_requirement: 0, load: 2
    end
  end

  # embedded structure must be a map but we should take advantage of field versioning
  defp embedded_encoder_protocol(fields_list) do
    quote location: :keep do
      defimpl Neo4ex.BoltProtocol.Encoder do
        def encode(struct, bolt_version) do
          valid_fields =
            unquote(fields_list)
            # pick fields that satisfy version requirement
            |> Enum.filter(&Structure.valid_field?(&1, bolt_version))

          struct
          |> Map.take(Keyword.keys(valid_fields))
          |> BoltEncoder.encode(bolt_version)
        end
      end
    end
  end

  defp encoder_protocol(fields_list) do
    quote location: :keep do
      defimpl Neo4ex.BoltProtocol.Encoder do
        alias Neo4ex.PackStream.{Markers, Exceptions}

        def encode(%module{} = struct, bolt_version) do
          if Version.match?(bolt_version, module.version_requirement()) do
            data =
              unquote(fields_list)
              # pick fields that satisfy version requirement
              |> Enum.filter(&Structure.valid_field?(&1, bolt_version))
              |> Enum.map(&Structure.encode(&1, struct, bolt_version))

            marker = Markers.get!(:struct)
            tag = module.get_tag()
            IO.iodata_to_binary([<<marker::4, length(data)::4, tag>>, data])
          else
            raise Exceptions.EncodeError, {module, bolt_version}
          end
        end
      end
    end
  end
end
