defmodule HairZippiker.Repo do
  use Ecto.Repo,
    otp_app: :hair_zippiker,
    adapter: Ecto.Adapters.Postgres
end
