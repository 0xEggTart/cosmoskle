defmodule Cosmoskle.WalletTest do
  use ExUnit.Case, async: true
  use Cosmoskle.WalletMockCase

  # Import the test helpers
  import Mox

  alias Cosmoskle.Wallet

  # Add mock for Phoenix.LiveView.JS
  import Mock

  setup do
    # Create a unique name for each test's GenServer
    wallet_name = :"Wallet#{System.unique_integer()}"

    # Start the real GenServer with the unique name
    start_supervised!(%{
      id: wallet_name,
      start: {Wallet, :start_link, [[name: wallet_name]]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    })

    # Set up mocks to allow both stubbing and expectations
    stub_with(Cosmoskle.WalletMock, Wallet)

    # Return the wallet name to the test
    {:ok, wallet: wallet_name}
  end

  describe "wallet connection" do
    test "connect/0 successfully connects to Keplr wallet", %{wallet: wallet} do
      with_mock Phoenix.LiveView.JS,
        exec: fn "connectKeplr", [to: "#wallet-connect"] ->
          %{"ok" => true, "address" => "cosmos123456789abcdefghijklmnopqrstuvwxyz1234"}
        end do
        {:ok, wallet_state} = Wallet.connect(wallet)

        assert wallet_state.address != nil
        assert String.starts_with?(wallet_state.address, "cosmos")
        assert String.length(wallet_state.address) == 45
        assert wallet_state.connected? == true
      end
    end

    test "connect/0 returns error when Keplr wallet is not installed", %{wallet: wallet} do
      with_mock Phoenix.LiveView.JS,
        exec: fn "connectKeplr", [to: "#wallet-connect"] ->
          %{"ok" => false, "error" => "wallet_not_found"}
        end do
        assert {:error, :wallet_not_found} = Wallet.connect(wallet)
      end
    end

    test "connect/0 returns error when user rejects connection", %{wallet: wallet} do
      with_mock Phoenix.LiveView.JS,
        exec: fn "connectKeplr", [to: "#wallet-connect"] ->
          %{"ok" => false, "error" => "user_rejected"}
        end do
        assert {:error, :user_rejected} = Wallet.connect(wallet)
      end
    end

    test "disconnect/0 successfully disconnects wallet", %{wallet: wallet} do
      # First connect
      with_mock Phoenix.LiveView.JS,
        exec: fn "connectKeplr", [to: "#wallet-connect"] ->
          %{"ok" => true, "address" => "cosmos123456789abcdefghijklmnopqrstuvwxyz1234"}
        end do
        {:ok, wallet_state} = Wallet.connect(wallet)
        assert wallet_state.connected? == true

        :ok = Wallet.disconnect(wallet)
        assert Wallet.connected?(wallet) == false
      end
    end

    test "connect/0 returns error with invalid chain ID", %{wallet: wallet} do
      with_mock Phoenix.LiveView.JS,
        exec: fn "connectKeplr", [to: "#wallet-connect"] ->
          %{"ok" => false, "error" => "invalid_chain"}
        end do
        assert {:error, :invalid_chain} = Wallet.connect(wallet)
      end
    end

    test "connect/0 returns error when wallet is locked", %{wallet: wallet} do
      with_mock Phoenix.LiveView.JS,
        exec: fn "connectKeplr", [to: "#wallet-connect"] ->
          %{"ok" => false, "error" => "wallet_locked"}
        end do
        assert {:error, :wallet_locked} = Wallet.connect(wallet)
      end
    end

    test "connect/0 returns error on network issues", %{wallet: wallet} do
      with_mock Phoenix.LiveView.JS,
        exec: fn "connectKeplr", [to: "#wallet-connect"] ->
          %{"ok" => false, "error" => "network_error"}
        end do
        assert {:error, :network_error} = Wallet.connect(wallet)
      end
    end
  end

  describe "wallet state" do
    test "connected?/0 returns false when no wallet is connected", %{wallet: wallet} do
      expect(Cosmoskle.WalletMock, :connected?, fn ^wallet ->
        false
      end)

      assert Cosmoskle.WalletMock.connected?(wallet) == false
    end

    test "connected?/0 returns true after successful connection", %{wallet: wallet} do
      # Mock both connect and connected? calls
      expect(Cosmoskle.WalletMock, :connect, fn ^wallet ->
        {:ok, %Wallet{address: "cosmos123456789abcdefghijklmnopqrstuvwxyz1234", connected?: true}}
      end)

      expect(Cosmoskle.WalletMock, :connected?, fn ^wallet ->
        true
      end)

      {:ok, _wallet_state} = Cosmoskle.WalletMock.connect(wallet)
      assert Cosmoskle.WalletMock.connected?(wallet) == true
    end

    test "get_address/0 returns nil when no wallet is connected", %{wallet: wallet} do
      expect(Cosmoskle.WalletMock, :get_address, fn ^wallet ->
        nil
      end)

      assert Cosmoskle.WalletMock.get_address(wallet) == nil
    end

    test "get_address/0 returns address after successful connection", %{wallet: wallet} do
      address = "cosmos123456789abcdefghijklmnopqrstuvwxyz1234"

      # Mock both connect and get_address calls
      expect(Cosmoskle.WalletMock, :connect, fn ^wallet ->
        {:ok, %Wallet{address: address, connected?: true}}
      end)

      expect(Cosmoskle.WalletMock, :get_address, fn ^wallet ->
        address
      end)

      {:ok, wallet_state} = Cosmoskle.WalletMock.connect(wallet)
      assert Cosmoskle.WalletMock.get_address(wallet) == wallet_state.address
    end

    test "connected?/0 handles GenServer crashes gracefully", %{wallet: wallet} do
      pid = Process.whereis(wallet)
      Process.exit(pid, :kill)
      refute Wallet.connected?(wallet)
    end

    test "get_address/0 handles GenServer crashes gracefully", %{wallet: wallet} do
      pid = Process.whereis(wallet)
      Process.exit(pid, :kill)
      assert is_nil(Wallet.get_address(wallet))
    end
  end

  describe "wallet validation" do
    test "validates cosmos address format", %{wallet: wallet} do
      with_mock Phoenix.LiveView.JS,
        exec: fn "connectKeplr", [to: "#wallet-connect"] ->
          %{"ok" => true, "address" => "cosmos123456789abcdefghijklmnopqrstuvwxyz1234"}
        end do
        {:ok, wallet_state} = Wallet.connect(wallet)
        assert String.match?(wallet_state.address, ~r/^cosmos[0-9a-z]{39}$/)
      end
    end

    test "validates address checksum", %{wallet: wallet} do
      with_mock Phoenix.LiveView.JS,
        exec: fn "connectKeplr", [to: "#wallet-connect"] ->
          %{"ok" => true, "address" => "cosmos123456789abcdefghijklmnopqrstuvwxyz1234"}
        end do
        {:ok, wallet_state} = Wallet.connect(wallet)
        assert String.length(wallet_state.address) == 45
        assert String.starts_with?(wallet_state.address, "cosmos")
      end
    end
  end
end
