defmodule LingoManager.Resources do
  @moduledoc """
  The Resources context.
  """

  import Ecto.Query, warn: false
  alias LingoManager.Repo
  alias LingoManager.Resources.Resource

  @doc """
  Returns the list of resources with pagination.
  """
  def list_resources(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 10)
    offset = (page - 1) * per_page

    resources = Resource
    |> preload(:current_user)
    |> order_by([r], desc: r.inserted_at)
    |> limit(^per_page)
    |> offset(^offset)
    |> Repo.all()

    total_count = Resource |> Repo.aggregate(:count, :id)
    total_pages = ceil(total_count / per_page)

    %{
      resources: resources,
      page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: total_pages,
      has_next: page < total_pages,
      has_prev: page > 1
    }
  end

  @doc """
  Returns the list of available resources.
  """
  def list_available_resources do
    Resource
    |> where([r], r.status == "available")
    |> preload(:current_user)
    |> Repo.all()
  end

  @doc """
  Returns the list of resources currently in use.
  """
  def list_in_use_resources do
    Resource
    |> where([r], r.status == "in_use")
    |> preload(:current_user)
    |> Repo.all()
  end

  @doc """
  Gets a single resource.
  """
  def get_resource!(id) do
    Resource
    |> preload(:current_user)
    |> Repo.get!(id)
  end

  @doc """
  Creates a resource.
  """
  def create_resource(attrs \\ %{}) do
    %Resource{}
    |> Resource.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a resource.
  """
  def update_resource(%Resource{} = resource, attrs) do
    resource
    |> Resource.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a resource.
  """
  def delete_resource(%Resource{} = resource) do
    Repo.delete(resource)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking resource changes.
  """
  def change_resource(%Resource{} = resource, attrs \\ %{}) do
    Resource.changeset(resource, attrs)
  end

  @doc """
  Marks a resource as in use by a specific user.
  """
  def mark_resource_in_use(%Resource{} = resource, user_id) do
    if Resource.available?(resource) do
      resource
      |> Resource.mark_in_use(user_id)
      |> Repo.update()
    else
      {:error, :resource_not_available}
    end
  end

  @doc """
  Marks a resource as available (releases it).
  """
  def mark_resource_available(%Resource{} = resource) do
    resource
    |> Resource.mark_available()
    |> Repo.update()
  end

  @doc """
  Gets resources currently used by a specific user.
  """
  def get_user_resources(user_id) do
    Resource
    |> where([r], r.current_user_id == ^user_id and r.status == "in_use")
    |> preload(:current_user)
    |> Repo.all()
  end

  @doc """
  Calculates the total unpaid balance for a resource.
  """
  def get_unpaid_balance(resource_id) do
    result = LingoManager.Tasks.Task
    |> where([t], t.resource_id == ^resource_id)
    |> where([t], t.paid == false)
    |> select([t], sum(t.task_value_dollars))
    |> Repo.one()

    result || Decimal.new(0)
  end
end