defmodule Cosmoskle.Repo do
  use Ecto.Repo,
    otp_app: :cosmoskle,
    adapter: Ecto.Adapters.Postgres
end
