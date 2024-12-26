defmodule Cosmoskle.Wallet do
  @moduledoc """
  Handles Keplr wallet connection and state management.
  """

  use GenServer
  @behaviour Cosmoskle.WalletBehaviour

  defstruct [:address, connected?: false]

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  @impl Cosmoskle.WalletBehaviour
  def connect do
    GenServer.call(__MODULE__, :connect)
  end

  @impl Cosmoskle.WalletBehaviour
  def disconnect do
    GenServer.call(__MODULE__, :disconnect)
  end

  @impl Cosmoskle.WalletBehaviour
  def connected? do
    GenServer.call(__MODULE__, :connected?)
  end

  @impl Cosmoskle.WalletBehaviour
  def get_address do
    GenServer.call(__MODULE__, :get_address)
  end

  # Server Callbacks

  @impl GenServer
  def init(state) do
    {:ok, state}
  end

  @impl GenServer
  def handle_call(:connect, _from, _state) do
    # TODO: Implement actual Keplr wallet connection
    # For now, return mock data for testing
    new_state = %__MODULE__{
      address: "cosmos123456789abcdefghijklmnopqrstuvwxyz1234",
      connected?: true
    }
    {:reply, {:ok, new_state}, new_state}
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
end 