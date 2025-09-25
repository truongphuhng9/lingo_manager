defmodule LingoManager.Repo.Migrations.CreateTimeLogs do
  use Ecto.Migration

  def change do
    create table(:time_logs) do
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :task_id, references(:tasks, on_delete: :nothing), null: false
      add :start_time, :naive_datetime, null: false
      add :end_time, :naive_datetime
      add :duration_minutes, :decimal, precision: 8, scale: 2
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:time_logs, [:user_id])
    create index(:time_logs, [:task_id])
    create index(:time_logs, [:start_time])
  end
end
