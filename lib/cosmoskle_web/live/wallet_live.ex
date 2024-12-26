defmodule CosmoskleWeb.WalletLive do
  use CosmoskleWeb, :live_view
  alias Cosmoskle.Wallet

  def mount(_params, _session, socket) do
    if connected?(socket) do
      {:ok,
       assign(socket,
         connected?: Wallet.connected?(),
         address: Wallet.get_address()
       )}
    else
      {:ok, assign(socket, connected?: false, address: nil)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-4">
      <div id="wallet-connect">
        <%= if @connected? do %>
          <div class="flex flex-col items-center gap-2">
            <span class="text-sm text-gray-600">Connected Address:</span>
            <code class="px-2 py-1 bg-gray-100 rounded">{@address}</code>
            <button
              phx-click="disconnect"
              class="px-4 py-2 text-sm text-red-600 border border-red-600 rounded hover:bg-red-50"
            >
              Disconnect Wallet
            </button>
          </div>
        <% else %>
          <button
            phx-click="connect"
            class="px-4 py-2 text-sm text-white bg-indigo-600 rounded hover:bg-indigo-700"
          >
            Connect Keplr Wallet
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("connect", _params, socket) do
    case Wallet.connect() do
      {:ok, wallet} ->
        {:noreply, assign(socket, connected?: true, address: wallet.address)}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  def handle_event("disconnect", _params, socket) do
    :ok = Wallet.disconnect()
    {:noreply, assign(socket, connected?: false, address: nil)}
  end
end
