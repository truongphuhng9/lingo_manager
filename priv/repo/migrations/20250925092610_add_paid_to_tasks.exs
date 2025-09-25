defmodule LingoManager.Repo.Migrations.AddPaidToTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :paid, :boolean, default: false
    end
  end
end
