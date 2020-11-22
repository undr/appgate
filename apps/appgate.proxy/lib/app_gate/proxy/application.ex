defmodule AppGate.Proxy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  require :cowboy_telemetry_h

  use Application

  def start(_type, _args) do
    :ok = :telemetry.attach_many(
      "appgate-proxy-cowboy-handler",
      [
        [:cowboy, :request, :start],
        [:cowboy, :request, :stop],
        [:cowboy, :request, :exception]
      ],
      &AppGate.Proxy.LogHandler.handle_cowboy_event/4,
      nil
    )

    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: AppGate.Proxy.Endpoint,
        options: [port: Application.get_env(:appgate_proxy, :port, 4000)]
      )
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AppGate.Proxy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
