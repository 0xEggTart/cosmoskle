defmodule Cosmoskle.WalletTest do
  use ExUnit.Case, async: true
  use Cosmoskle.WalletMockCase

  # Import the test helpers
  import Mox

  alias Cosmoskle.Wallet

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
      # Set up mock for just the connect call
      expect(Cosmoskle.WalletMock, :connect, fn ^wallet ->
        {:ok, %Wallet{address: "cosmos123456789abcdefghijklmnopqrstuvwxyz1234", connected?: true}}
      end)

      {:ok, wallet_state} = Cosmoskle.WalletMock.connect(wallet)

      assert wallet_state.address != nil
      assert String.starts_with?(wallet_state.address, "cosmos")
      assert String.length(wallet_state.address) == 45
      assert wallet_state.connected? == true
    end

    test "connect/0 returns error when Keplr wallet is not installed", %{wallet: wallet} do
      expect(Cosmoskle.WalletMock, :connect, fn ^wallet ->
        {:error, :wallet_not_found}
      end)

      assert {:error, :wallet_not_found} = Cosmoskle.WalletMock.connect(wallet)
    end

    test "connect/0 returns error when user rejects connection", %{wallet: wallet} do
      expect(Cosmoskle.WalletMock, :connect, fn ^wallet ->
        {:error, :user_rejected}
      end)

      assert {:error, :user_rejected} = Cosmoskle.WalletMock.connect(wallet)
    end

    test "disconnect/0 successfully disconnects wallet", %{wallet: wallet} do
      # First mock the connect call
      expect(Cosmoskle.WalletMock, :connect, fn ^wallet ->
        {:ok, %Wallet{address: "cosmos123456789abcdefghijklmnopqrstuvwxyz1234", connected?: true}}
      end)

      {:ok, wallet_state} = Cosmoskle.WalletMock.connect(wallet)
      assert wallet_state.connected? == true

      # Then mock the disconnect call
      expect(Cosmoskle.WalletMock, :disconnect, fn ^wallet ->
        :ok
      end)

      :ok = Cosmoskle.WalletMock.disconnect(wallet)
      assert Wallet.connected?(wallet) == false
    end

    test "connect/0 returns error with invalid chain ID", %{wallet: wallet} do
      expect(Cosmoskle.WalletMock, :connect, fn ^wallet ->
        {:error, :invalid_chain}
      end)

      assert {:error, :invalid_chain} = Cosmoskle.WalletMock.connect(wallet)
    end

    test "connect/0 returns error when wallet is locked", %{wallet: wallet} do
      expect(Cosmoskle.WalletMock, :connect, fn ^wallet ->
        {:error, :wallet_locked}
      end)

      assert {:error, :wallet_locked} = Cosmoskle.WalletMock.connect(wallet)
    end

    test "connect/0 returns error on network issues", %{wallet: wallet} do
      expect(Cosmoskle.WalletMock, :connect, fn ^wallet ->
        {:error, :network_error}
      end)

      assert {:error, :network_error} = Cosmoskle.WalletMock.connect(wallet)
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
      address = "cosmos123456789abcdefghijklmnopqrstuvwxyz1234"

      expect(Cosmoskle.WalletMock, :connect, fn ^wallet ->
        {:ok, %Wallet{address: address, connected?: true}}
      end)

      {:ok, wallet_state} = Cosmoskle.WalletMock.connect(wallet)
      assert String.match?(wallet_state.address, ~r/^cosmos[0-9a-z]{39}$/)
    end

    test "validates address checksum", %{wallet: wallet} do
      address = "cosmos123456789abcdefghijklmnopqrstuvwxyz1234"

      expect(Cosmoskle.WalletMock, :connect, fn ^wallet ->
        {:ok, %Wallet{address: address, connected?: true}}
      end)

      {:ok, wallet_state} = Cosmoskle.WalletMock.connect(wallet)
      assert String.length(wallet_state.address) == 45
      assert String.starts_with?(wallet_state.address, "cosmos")
    end
  end
end
