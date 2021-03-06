defmodule ExqUi do
  use Application
  import Supervisor.Spec, warn: false

  def start(_type, _args) do
    launch_app()
  end

  def launch_app do
    web_port = Application.get_env(:exq_ui, :web_port, 4040)
    web_namespace = Application.get_env(:exq_ui, :web_namespace, "")
    run_server? = Application.get_env(:exq_ui, :server, true)

    api_name = Exq.Api.Server.server_name(ExqUi)

    unless Process.whereis(api_name) do
      {:ok, _} = Exq.start_link(name: ExqUi, mode: :api)
    end

    {:ok, _} = Exq.Api.queue_size(api_name)

    if run_server? do
      IO.puts "Starting ExqUI on Port #{web_port}"
      cowboy_version_adapter().http ExqUi.RouterPlug,
        [namespace: web_namespace, exq_opts: [name: api_name]], port: web_port
    end
    Supervisor.start_link([], strategy: :one_for_one)
  end

  defp cowboy_version_adapter() do
    case :application.get_key(:cowboy, :vsn) do
      [?1 | _] -> Plug.Adapters.Cowboy
      _ -> Plug.Adapters.Cowboy2
    end
  end
end
