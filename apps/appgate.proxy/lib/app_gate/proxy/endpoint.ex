defmodule AppGate.Proxy.Endpoint do
  use Plug.Builder
  use Plug.ErrorHandler

  plug Plug.RequestId
  plug Plug.Logger
  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    json_decoder: Jason

  plug Plug.MethodOverride
  plug AppGate.Proxy.Plug
end
