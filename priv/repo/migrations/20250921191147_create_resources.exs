defmodule LingoManager.Repo.Migrations.CreateResources do
  use Ecto.Migration

  def change do
    create table(:resources) do
      add :name, :string, null: false
      add :description, :text
      add :resource_type, :string, null: false
      add :status, :string, default: "available", null: false
      add :current_user_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:resources, [:current_user_id])
    create index(:resources, [:status])
  end
end
