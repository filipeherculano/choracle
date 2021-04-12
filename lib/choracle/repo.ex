defmodule Choracle.Repo do
  use Ecto.Repo,
    otp_app: :choracle,
    adapter: Ecto.Adapters.Postgres
end
