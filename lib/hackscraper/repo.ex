defmodule Hackscraper.Repo do
  use Ecto.Repo,
    otp_app: :hackscraper,
    adapter: Ecto.Adapters.Postgres
end
