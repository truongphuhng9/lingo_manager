defmodule LingoManager.Repo.Migrations.CreateTimesheets do
  use Ecto.Migration

  def change do
    create table(:timesheets) do
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :resource_id, references(:resources, on_delete: :nothing), null: false
      add :planned_start_time, :naive_datetime, null: false
      add :planned_end_time, :naive_datetime, null: false
      add :status, :string, default: "registered", null: false

      timestamps(type: :utc_datetime)
    end

    create index(:timesheets, [:user_id])
    create index(:timesheets, [:resource_id])
    create unique_index(:timesheets, [:resource_id, :planned_start_time, :planned_end_time],
           name: :timesheets_resource_time_overlap_index,
           where: "status != 'cancelled'")
  end
end
