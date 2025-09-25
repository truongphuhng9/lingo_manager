defmodule LingoManager.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LingoManagerWeb.Telemetry,
      LingoManager.Repo,
      {DNSCluster, query: Application.get_env(:lingo_manager, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LingoManager.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: LingoManager.Finch},
      # Start a worker by calling: LingoManager.Worker.start_link(arg)
      # {LingoManager.Worker, arg},
      # Start to serve requests, typically the last entry
      LingoManagerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LingoManager.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LingoManagerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
