defmodule AppGate.Proxy.Plug do
  alias AppGate.Proxy.Http
  alias AppGate.Proxy.Http.Request
  alias AppGate.Proxy.Http.Response
  alias Plug.Conn

  def init([]),
    do: []

  def call(conn, []) do
    conn
    |> build_request()
    |> request_upstream()
    |> assign_response(conn)
  end

  defp assign_response({:ok, %Response{status: status, body: body, headers: headers}}, conn) do
    conn
    |> Conn.prepend_resp_headers(headers)
    |> Conn.send_resp(status, body)
  end
  defp assign_response({:error, reason}, conn) do
    Conn.send_resp(conn, 502, Jason.encode!(%{
      type: :upstream_error,
      message: "Upstream is unavailable with reason #{inspect reason}"
    }))
  end

  defp request_upstream(request),
    do: Http.call(request)

  defp build_request(conn) do
    %Request{
      method: conn.method,
      scheme: :http,
      host: conn.host,
      port: nil,
      path: conn.request_path,
      body_params: conn.body_params,
      query_params: conn.query_params,
      headers: conn.req_headers
    }
  end
end
