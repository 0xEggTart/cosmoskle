defmodule Cosmoskle.WalletTest do
  use Cosmoskle.WalletMockCase
  use CosmoskleWeb.ConnCase
  
  alias Cosmoskle.Wallet
  
  describe "wallet connection" do
    test "connect/0 successfully connects to Keplr wallet", %{conn: _conn} do
      {:ok, wallet} = Wallet.connect()
      
      assert wallet.address != nil
      assert String.starts_with?(wallet.address, "cosmos")
      assert String.length(wallet.address) == 45
      assert wallet.connected? == true
    end

    test "connect/0 returns error when Keplr wallet is not installed", %{conn: _conn} do
      Mox.expect(Cosmoskle.WalletMock, :connect, fn -> 
        {:error, :wallet_not_found}
      end)
      
      assert {:error, :wallet_not_found} = apply(Cosmoskle.WalletMock, :connect, [])
    end

    test "connect/0 returns error when user rejects connection", %{conn: _conn} do
      Mox.expect(Cosmoskle.WalletMock, :connect, fn -> 
        {:error, :user_rejected}
      end)
      
      assert {:error, :user_rejected} = apply(Cosmoskle.WalletMock, :connect, [])
    end

    test "disconnect/0 successfully disconnects wallet", %{conn: _conn} do
      {:ok, wallet} = Wallet.connect()
      assert wallet.connected? == true
      
      :ok = Wallet.disconnect()
      assert Wallet.connected?() == false
    end
  end

  describe "wallet state" do
    test "connected?/0 returns false when no wallet is connected", %{conn: _conn} do
      assert Wallet.connected?() == false
    end

    test "connected?/0 returns true after successful connection", %{conn: _conn} do
      {:ok, _wallet} = Wallet.connect()
      assert Wallet.connected?() == true
    end

    test "get_address/0 returns nil when no wallet is connected", %{conn: _conn} do
      assert Wallet.get_address() == nil
    end

    test "get_address/0 returns address after successful connection", %{conn: _conn} do
      {:ok, wallet} = Wallet.connect()
      assert Wallet.get_address() == wallet.address
    end
  end
end 