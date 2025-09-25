defmodule LingoManager.Resources.Resource do
  use Ecto.Schema
  import Ecto.Changeset

  schema "resources" do
    field :name, :string
    field :description, :string
    field :resource_type, :string
    field :status, :string, default: "available"
    belongs_to :current_user, LingoManager.Accounts.User
    has_many :tasks, LingoManager.Tasks.Task

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:name, :description, :resource_type, :status, :current_user_id])
    |> validate_required([:name, :resource_type])
    |> validate_inclusion(:status, ["available", "in_use", "maintenance", "disabled"])
    |> validate_inclusion(:resource_type, ["account", "server", "service", "other"])
  end

  def mark_in_use(resource, user_id) do
    resource
    |> change(status: "in_use", current_user_id: user_id)
  end

  def mark_available(resource) do
    resource
    |> change(status: "available", current_user_id: nil)
  end

  def available?(resource) do
    resource.status == "available"
  end

  def in_use?(resource) do
    resource.status == "in_use"
  end
end