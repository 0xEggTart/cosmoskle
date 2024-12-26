defmodule CosmoskleWeb.WalletLiveTest do
  use CosmoskleWeb.ConnCase
  use CosmoskleWeb.WalletLiveCase
  import Phoenix.LiveViewTest

  alias Cosmoskle.Wallet

  describe "WalletLive" do
    test "renders connect button when wallet is not connected", %{conn: conn} do
      with_mock Wallet, [:passthrough], mock_disconnected_wallet() do
        {:ok, _view, html} = live(conn, "/wallet")

        assert html =~ "Connect Keplr Wallet"
        refute html =~ "Disconnect Wallet"
      end
    end

    test "renders wallet info when connected", %{conn: conn} do
      address = "cosmos123456789abcdefghijklmnopqrstuvwxyz1234"

      with_mock Wallet, [:passthrough],
        connected?: fn -> true end,
        get_address: fn -> address end do
        {:ok, _view, html} = live(conn, "/wallet")

        assert html =~ "Connected Address:"
        assert html =~ address
        assert html =~ "Disconnect Wallet"
      end
    end

    test "connects wallet successfully", %{conn: conn} do
      address = "cosmos123456789abcdefghijklmnopqrstuvwxyz1234"

      with_mock Wallet, [:passthrough],
        connected?: fn -> false end,
        get_address: fn -> nil end,
        connect: fn -> {:ok, %Wallet{address: address, connected?: true}} end do
        {:ok, view, _html} = live(conn, "/wallet")

        assert view
               |> element("button", "Connect Keplr Wallet")
               |> render_click() =~ address
      end
    end

    test "handles connection failure", %{conn: conn} do
      with_mock Wallet, [:passthrough],
        connected?: fn -> false end,
        get_address: fn -> nil end,
        connect: fn -> {:error, :wallet_not_found} end do
        {:ok, view, _html} = live(conn, "/wallet")

        assert view
               |> element("button", "Connect Keplr Wallet")
               |> render_click() =~ "Connect Keplr Wallet"
      end
    end

    test "disconnects wallet", %{conn: conn} do
      address = "cosmos123456789abcdefghijklmnopqrstuvwxyz1234"

      with_mock Wallet, [:passthrough],
        connected?: fn -> true end,
        get_address: fn -> address end,
        disconnect: fn -> :ok end do
        {:ok, view, _html} = live(conn, "/wallet")

        refute view
               |> element("button", "Disconnect Wallet")
               |> render_click() =~ address
      end
    end
  end
end
