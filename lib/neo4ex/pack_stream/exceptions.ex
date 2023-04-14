defmodule Neo4ex.PackStream.Exceptions do
  @moduledoc false

  defmodule EncodeError do
    defexception [:message]
    @impl true
    def exception({module, version}) do
      msg = "Encoding is not supported for #{module} in version #{version}"
      %EncodeError{message: msg}
    end
  end
end
