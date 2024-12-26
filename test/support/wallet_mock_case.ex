defmodule Cosmoskle.WalletMockCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a wallet mock.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Mox
      
      # Make sure mocks are verified when the test exits
      setup :verify_on_exit!
      
      # Allow the mock to be shared between processes
      setup :set_mox_from_context

      # Stub the mock implementation to fall back to the real module
      setup do
        Mox.stub_with(Cosmoskle.WalletMock, Cosmoskle.Wallet)
        :ok
      end
    end
  end
end 