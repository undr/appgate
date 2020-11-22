defmodule AppGate.Proxy.Http do
  alias AppGate.Proxy.Http.Request
  alias AppGate.Proxy.Http.Compression

  @callback connect(atom(), String.t(), pos_integer()) :: {:ok, pid()} | {:error, any()}
  @callback connect(atom(), String.t(), pos_integer(), Keyword.t()) :: {:ok, pid()} | {:error, any()}
  @callback disconnect(pid()) :: nil
  @callback request(pid(), String.t(), String.t(), list()) :: struct()
  @callback request(pid(), String.t(), String.t(), list(), String.t() | nil) :: struct()

  defmacro __using__(_opts) do
    quote do
      require Logger

      @behaviour unquote(__MODULE__)

      @prohibited_req_headers ["connection", "content-length"]
      @prohibited_resp_headers ["transfer-encoding"]

      def disconnect(_conn),
        do: log("disconnect")

      defp log(phase, values \\ []) do
        values = Enum.map(values, &inspect(&1, pretty: true)) |> Enum.join("\n")
        Logger.debug("AppGate.Proxy.Http[#{phase}]\n#{values}")
      end

      defp strip_req_headers(headers),
        do: Enum.reject(headers, fn({name, _}) -> name in @prohibited_req_headers end)

      defp strip_resp_headers(headers),
        do: Enum.reject(headers, fn({name, _}) -> name in @prohibited_resp_headers end)

      defoverridable [disconnect: 1]
    end
  end

  def call(%Request{} = request) do
    adapter = adapter()

    {:ok, conn} = adapter.connect(
      Request.scheme(request),
      Request.host(request),
      Request.port(request),
      [keepalive: 1000]
    )

    try do
      {:ok, response} = adapter.request(
        conn,
        Request.method(request),
        Request.query(request),
        Request.headers(request),
        Request.body(request)
      )

      {:ok, Compression.decompress(response)}
    after
      adapter.disconnect(conn)
    end
  end

  defp adapter do
    Application.get_env(:appgate_proxy, :adapter, AppGate.Proxy.Http.Gun)
  end
end
