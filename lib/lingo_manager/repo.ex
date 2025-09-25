defmodule LingoManager.Repo do
  use Ecto.Repo,
    otp_app: :lingo_manager,
    adapter: Ecto.Adapters.Postgres
end
