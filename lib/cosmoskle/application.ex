defmodule Cosmoskle.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CosmoskleWeb.Telemetry,
      Cosmoskle.Repo,
      {DNSCluster, query: Application.get_env(:cosmoskle, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Cosmoskle.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Cosmoskle.Finch},
      # Start a worker by calling: Cosmoskle.Worker.start_link(arg)
      # {Cosmoskle.Worker, arg},
      # Start to serve requests, typically the last entry
      CosmoskleWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Cosmoskle.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CosmoskleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
