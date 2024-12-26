defmodule Cosmoskle.WalletBehaviour do
  @moduledoc """
  Defines the behaviour for wallet interactions.
  """

  @callback connect() :: {:ok, map()} | {:error, :wallet_not_found | :user_rejected}
  @callback disconnect() :: :ok
  @callback connected?() :: boolean()
  @callback get_address() :: String.t() | nil
end 