defmodule AppGate.Proxy.Http.GunOptions do
  @retry 10
  @retry_timeout 100
  @connect_timeout :timer.minutes(1)
  @keepalive :infinity
  @connect_opts [:retry, :retry_timeout, :connect_timeout, :keepalive]

  def get_connect_options(opts),
    do: connect_options(@connect_opts, opts)

  defp connect_options(keys, opts, result \\ [])
  defp connect_options([:keepalive | keys], opts, result) do
    value = opts[:keepalive] || @keepalive
    result = [{:http_opts, %{keepalive: value}} | result]
    result = [{:http2_opts, %{keepalive: value}} | result]
    connect_options(keys, opts, result)
  end

  defp connect_options([:connect_timeout | keys], opts, result),
    do: connect_options(keys, opts, [{:connect_timeout, opts[:connect_timeout] || @connect_timeout} | result])

  defp connect_options([:retry | keys], opts, result),
    do: connect_options(keys, opts, [{:retry, opts[:retry] || @retry} | result])

  defp connect_options([:retry_timeout | keys], opts, result),
    do: connect_options(keys, opts, [{:retry_timeout, opts[:retry_timeout] || @retry_timeout} | result])

  defp connect_options([], _opts, result),
    do: Enum.into(result, %{})
end
