defmodule HairZippiker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HairZippikerWeb.Telemetry,
      HairZippiker.Repo,
      {DNSCluster, query: Application.get_env(:hair_zippiker, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: HairZippiker.PubSub},
      # Start a worker by calling: HairZippiker.Worker.start_link(arg)
      # {HairZippiker.Worker, arg},
      # Start to serve requests, typically the last entry
      HairZippikerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HairZippiker.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HairZippikerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
