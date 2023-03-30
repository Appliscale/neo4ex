defmodule Neo4Ex.PackStream.Exceptions do
  @moduledoc false

  defmodule EncodeError do
    defexception [:message]
    @impl true
    def exception({module, version}) do
      msg = "Encoding is not supported for #{module} in version #{version}"
      %EncodeError{message: msg}
    end
  end

  defmodule MarkersError do
    defexception [:message]
    @impl true
    def exception(value) do
      msg = "Couldn't find markers for #{inspect(value)}"
      %MarkersError{message: msg}
    end
  end
end
