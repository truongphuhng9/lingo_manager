defmodule LingoManager.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :task_id, :string, null: false
      add :start_datetime, :naive_datetime, null: false
      add :audio_length_minutes, :decimal, precision: 8, scale: 2
      add :task_value_dollars, :decimal, precision: 10, scale: 2, null: false
      add :rate_per_hour, :decimal, precision: 8, scale: 2, null: false
      add :status, :string, default: "pending", null: false
      add :finished_at, :naive_datetime
      add :assigned_user_id, references(:users, on_delete: :nilify_all)
      add :resource_id, references(:resources, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:tasks, [:assigned_user_id])
    create index(:tasks, [:resource_id])
    create index(:tasks, [:status])
    create index(:tasks, [:task_id])
  end
end
