defmodule Cosmoskle.Wallet do
  @moduledoc """
  Handles Keplr wallet connection and state management.
  """

  use GenServer
  @behaviour Cosmoskle.WalletBehaviour

  defstruct [:address, connected?: false]

  # Client API

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: name)
  end

  @impl Cosmoskle.WalletBehaviour
  def connect(server \\ __MODULE__) do
    GenServer.call(server, :connect)
  end

  @impl Cosmoskle.WalletBehaviour
  def disconnect(server \\ __MODULE__) do
    GenServer.call(server, :disconnect)
  end

  @impl Cosmoskle.WalletBehaviour
  def connected?(server \\ __MODULE__) do
    try do
      GenServer.call(server, :connected?)
    catch
      :exit, _ -> false
    end
  end

  @impl Cosmoskle.WalletBehaviour
  def get_address(server \\ __MODULE__) do
    try do
      GenServer.call(server, :get_address)
    catch
      :exit, _ -> nil
    end
  end

  # Server Callbacks

  @impl GenServer
  def init(_state) do
    {:ok, %__MODULE__{connected?: false, address: nil}}
  end

  @impl GenServer
  def handle_call(:connect, _from, state) do
    case connect_to_keplr() do
      {:ok, address} ->
        new_state = %__MODULE__{
          address: address,
          connected?: true
        }

        {:reply, {:ok, new_state}, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl GenServer
  def handle_call(:disconnect, _from, _state) do
    new_state = %__MODULE__{connected?: false, address: nil}
    {:reply, :ok, new_state}
  end

  @impl GenServer
  def handle_call(:connected?, _from, state) do
    {:reply, state.connected?, state}
  end

  @impl GenServer
  def handle_call(:get_address, _from, state) do
    {:reply, state.address, state}
  end

  defp connect_to_keplr do
    case Phoenix.LiveView.JS.exec("connectKeplr", to: "#wallet-connect") do
      %{"ok" => true, "address" => address} ->
        {:ok, address}

      %{"ok" => false, "error" => error} ->
        {:error, String.to_atom(error)}

      _ ->
        {:error, :network_error}
    end
  end
end
