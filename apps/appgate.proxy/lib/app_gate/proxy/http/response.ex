defmodule AppGate.Proxy.Http.Response do
  defstruct [:status, :body, headers: []]
end
