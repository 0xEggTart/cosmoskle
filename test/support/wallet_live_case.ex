defmodule CosmoskleWeb.WalletLiveCase do
  @moduledoc """
  This module defines test helpers for wallet LiveView tests.
  """

  defmacro __using__(_opts) do
    quote do
      import Mock

      setup do
        address = "cosmos123456789abcdefghijklmnopqrstuvwxyz1234"
        {:ok, address: address}
      end

      def mock_connected_wallet(address) do
        [
          connected?: fn -> true end,
          get_address: fn -> address end
        ]
      end

      def mock_disconnected_wallet do
        [
          connected?: fn -> false end,
          get_address: fn -> nil end
        ]
      end
    end
  end
end
