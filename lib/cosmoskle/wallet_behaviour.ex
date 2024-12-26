defmodule Cosmoskle.WalletBehaviour do
  @moduledoc """
  Defines the behaviour for wallet interactions.
  """

  @callback connect(server :: atom()) :: {:ok, map()} | {:error, :wallet_not_found | :user_rejected}
  @callback disconnect(server :: atom()) :: :ok
  @callback connected?(server :: atom()) :: boolean()
  @callback get_address(server :: atom()) :: String.t() | nil
end 