defmodule AppGate.Proxy.Http.Compression do
  @header "content-encoding"
  @algorithms ["gzip", "x-gzip", "deflate", "identity"]

  def algorithms(),
    do: @algorithms

  def decompress(%{body: body, headers: headers} = entity) do
    body = headers
    |> get_algorithms()
    |> decompress_body(body)

    headers = set_algorithms(headers, nil)

    %{entity | body: body, headers: headers}
  end

  def compress(%{body: body, headers: headers} = entity, algorithm) when algorithm in @algorithms do
    body = compress_with_algorithm(algorithm, body)
    headers = set_algorithms(headers, algorithm)

    %{entity | body: body, headers: headers}
  end
  def compress(entity, _algorithm),
    do: compress(entity, "identity")

  defp compress_with_algorithm(gzip, body) when gzip in ["gzip", "x-gzip"],
    do: :zlib.gzip(body)

  defp compress_with_algorithm("deflate", body),
    do: :zlib.zip(body)

  defp compress_with_algorithm("identity", body),
    do: body

  defp decompress_body(algorithms, body),
    do: Enum.reduce(algorithms, body, &decompress_with_algorithm/2)

  defp decompress_with_algorithm(gzip, body) when gzip in ["gzip", "x-gzip"],
    do: :zlib.gunzip(body)

  defp decompress_with_algorithm("deflate", body),
    do: :zlib.unzip(body)

  defp decompress_with_algorithm("identity", body),
    do: body

  defp decompress_with_algorithm(algorithm, _body),
    do: raise "unsupported decompression algorithm: #{inspect(algorithm)}"

  defp set_algorithms(headers, nil),
    do: List.keydelete(headers, @header, 0)
  defp set_algorithms(headers, algorithm),
    do: List.keystore(headers, @header, 0, {@header, algorithm})

  defp get_algorithms(headers) do
    Enum.find_value(headers, [], fn {name, value} ->
      if String.downcase(name) == "content-encoding" do
        value
        |> String.downcase()
        |> String.split(",", trim: true)
        |> Stream.map(&String.trim/1)
        |> Enum.reverse()
      else
        nil
      end
    end)
  end
end
