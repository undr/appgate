defmodule AppGate.Proxy.Http.Request do
  defstruct [
    :method,
    :scheme,
    :host,
    :port,
    :path,
    :query_params,
    :body_params,
    headers: [],
  ]

  def scheme(%__MODULE__{scheme: scheme}) do
    scheme
  end

  def host(%__MODULE__{host: host}),
    do: host

  def headers(%__MODULE__{headers: headers}),
    do: headers

  def method(%__MODULE__{method: method}),
    do: method |> to_string() |> String.upcase()

  def query(%__MODULE__{path: path, query_params: query_params}),
    do: "#{path}#{encode_query(query_params)}"

  def body(%__MODULE__{body_params: nil}),
    do: nil
  def body(%__MODULE__{body_params: body_params}) when body_params == %{},
    do: nil
  def body(%__MODULE__{body_params: body_params}),
    do: Jason.encode!(body_params)

  def port(%__MODULE__{scheme: scheme, port: nil}),
    do: scheme |> to_string() |> URI.default_port()
  def port(%__MODULE__{port: port}),
    do: port

  defp encode_query(nil),
    do: ""
  defp encode_query(query_params) when query_params == %{},
    do: ""
  defp encode_query(query_params),
    do: "?#{URI.encode_query(query_params)}"
end
