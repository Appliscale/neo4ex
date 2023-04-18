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

  defmodule SizeError do
    defexception message:
                   "Encoding is not supported for collections larger than 32-bit signed integer"
  end
end
