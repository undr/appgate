defmodule AppGate.Proxy.Http.Shotgun do
  alias AppGate.Proxy.Http.Response
  alias AppGate.Proxy.Http.GunOptions

  use AppGate.Proxy.Http

  def connect(scheme, host, port),
    do: connect(scheme, host, port, [])
  def connect(scheme, host, port, opts) do
    gun_opts = GunOptions.get_connect_options(opts)
    opts = %{timeout: opts[:timeout] || :timer.minutes(1), gun_opts: gun_opts}
    host = to_charlist(host)

    log("connect", [scheme, host, port, opts])

    :shotgun.open(host, port, scheme, opts)
  end

  def request(conn, method, query, headers),
    do: request(conn, method, query, headers, nil)
  def request(conn, method, query, headers, body) do
    headers = strip_req_headers(headers)
    query = to_charlist(query)
    body = to_charlist(body)

    log("request", [method, query, headers, body])

    {:ok, %{status_code: status, headers: resp_headers, body: resp_body}} =
      :shotgun.request(conn, symbolized_method(method), query, headers, body, %{})

    log("response", [status, resp_headers, resp_body])

    {:ok, %Response{status: status, headers: strip_resp_headers(resp_headers), body: resp_body}}
  end

  def disconnect(conn) do
    log("disconnect")
    :shotgun.close(conn)
  end

  defp symbolized_method(method) when is_atom(method),
    do: method
  defp symbolized_method(method) when is_binary(method),
    do: String.downcase(method) |> String.to_atom()
end
