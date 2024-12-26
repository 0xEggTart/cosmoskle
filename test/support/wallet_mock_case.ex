defmodule Cosmoskle.WalletMockCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a wallet mock.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Mox
      
      # Verify that the mock is valid when the test exits
      setup :verify_on_exit!
      
      # Allow non-global functions to be mocked
      setup do
        Mox.stub_with(Cosmoskle.WalletMock, Cosmoskle.Wallet)
        :ok
      end
    end
  end
end 