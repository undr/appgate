defmodule AppGate.Proxy.Http.Gun do
  alias AppGate.Proxy.Http.Response
  alias AppGate.Proxy.Http.GunOptions

  use AppGate.Proxy.Http

  def connect(_scheme, host, port, opts \\ []) do
    connect_opts = GunOptions.get_connect_options(opts)
    host = to_charlist(host)

    log("connect", [host, port, connect_opts])

    with {:ok, conn} <- :gun.open(host, port, connect_opts),
         {:ok, _protocol} <- :gun.await_up(conn, connect_opts[:connect_timeout]) do
      {:ok, conn}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def request(conn, method, query, headers),
    do: request(conn, method, query, headers, nil)
  def request(conn, "GET", query, headers, _body) do
    monitor_ref = Process.monitor(conn)
    headers = convert_to_elixir(headers)
    headers = strip_req_headers(headers)
    query = to_charlist(query)

    log("request", ["GET", query, headers])

    stream_ref = :gun.get(conn, query, headers)

    {:ok, async_response(conn, stream_ref, monitor_ref)}
  end
  def request(conn, "POST", query, headers, body),
    do: request_with_body(conn, query, headers, body, &:gun.post/4)
  def request(conn, "PUT", query, headers, body),
    do: request_with_body(conn, query, headers, body, &:gun.put/4)
  def request(conn, "PATCH", query, headers, body),
    do: request_with_body(conn, query, headers, body, &:gun.patch/4)
  def request(conn, "DELETE", query, headers, body),
    do: request_with_body(conn, query, headers, body, &:gun.delete/4)

  defp request_with_body(conn, query, headers, body, func) do
    monitor_ref = Process.monitor(conn)
    headers = convert_to_elixir(headers)
    headers = strip_req_headers(headers)
    query = to_charlist(query)

    headers = [{"content-length", byte_size(body)} | headers]

    log("request", ["POST", query, headers, body])

    stream_ref = func.(conn, query, headers, body)

    {:ok, async_response(conn, stream_ref, monitor_ref)}
  end

  defp async_response(conn, stream_ref, monitor_ref) do
    receive do
      {:gun_response, ^conn, ^stream_ref, :fin, status, headers} ->
        %Response{status: status, body: "", headers: headers}

      {:gun_response, ^conn, ^stream_ref, :nofin, status, headers} ->
        case receive_data(conn, stream_ref, monitor_ref, "") do
          {:ok, data} ->
            %Response{status: status, body: data, headers: headers}

          {:error, reason} ->
            {:error, reason}
        end

      {:gun_error, ^conn, ^stream_ref, reason} ->
        {:error, reason}

      {:gun_error, ^conn, error} ->
        {:error, error}

      {:gun_down, ^conn, _protocol, _reason, _killed_streams, _unprocessed_streams} ->
        {:error, :gun_down}

      {:DOWN, ^monitor_ref, :process, ^conn, reason} ->
        {:error, reason}
    after
      :timer.minutes(5) ->
        {:error, :recv_timeout}
    end
  end

  defp receive_data(conn, stream_ref, monitor_ref, response_data) do
    receive do
      {:gun_data, ^conn, ^stream_ref, :fin, data} ->
        {:ok, response_data <> data}

      {:gun_data, ^conn, ^stream_ref, :nofin, data} ->
        receive_data(conn, stream_ref, monitor_ref, response_data <> data)

      {:gun_down, ^conn, _protocol, reason, _killed_streams, _unprocessed_streams} ->
        {:error, reason}

      {:DOWN, ^monitor_ref, :process, ^conn, reason} ->
        {:error, reason}
    after
      :timer.minutes(5) ->
        {:error, :recv_timeout}
    end
  end

  defp convert_to_elixir(headers) do
    Enum.map(headers, fn({name, value}) ->
      {name, to_charlist(value)}
    end)
  end
end
