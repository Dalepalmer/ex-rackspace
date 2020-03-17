defmodule Rackspace.Error do
  @type t :: %__MODULE__{
          code: String.t() | nil,
          message: String.t()
        }

  defexception code: nil,
               message: "something went wrong"
end

defmodule Rackspace.ConfigError do
  @type t :: %__MODULE__{
          message: String.t()
        }

  defexception [:message]
end
