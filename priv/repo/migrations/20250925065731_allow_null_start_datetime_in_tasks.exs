defmodule LingoManager.Repo.Migrations.AllowNullStartDatetimeInTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      modify :start_datetime, :naive_datetime, null: true
    end
  end
end
