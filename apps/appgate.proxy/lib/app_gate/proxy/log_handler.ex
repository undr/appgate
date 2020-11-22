defmodule AppGate.Proxy.LogHandler do
  require Logger

  def handle_cowboy_event(event, measurements, metadata, _config) do
    Logger.info("Event: #{inspect(event, pretty: true)}")
    Logger.info("Measurements: #{inspect(measurements, pretty: true)}")
    Logger.info("Metadata: #{inspect(metadata, pretty: true)}")
  end
end
