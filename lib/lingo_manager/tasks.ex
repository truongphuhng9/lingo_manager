defmodule LingoManager.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto.Query, warn: false
  alias LingoManager.Repo
  alias LingoManager.Tasks.Task
  alias LingoManager.Resources

  @doc """
  Returns the list of tasks for a specific user.
  """
  def list_user_tasks(user_id) do
    Task
    |> where([t], t.assigned_user_id == ^user_id)
    |> preload([:assigned_user, :resource])
    |> order_by([t], desc: t.inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns paginated tasks for a specific user.
  """
  def list_user_tasks_paginated(user_id, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 10)
    offset = (page - 1) * per_page

    tasks = Task
    |> where([t], t.assigned_user_id == ^user_id)
    |> preload([:assigned_user, :resource])
    |> order_by([t], desc: t.inserted_at)
    |> limit(^per_page)
    |> offset(^offset)
    |> Repo.all()

    total_count = Task
    |> where([t], t.assigned_user_id == ^user_id)
    |> Repo.aggregate(:count, :id)

    total_pages = ceil(total_count / per_page)

    %{
      tasks: tasks,
      page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: total_pages,
      has_next: page < total_pages,
      has_prev: page > 1
    }
  end

  @doc """
  Returns the list of tasks for a specific resource.
  """
  def list_resource_tasks(resource_id) do
    Task
    |> where([t], t.resource_id == ^resource_id)
    |> preload([:assigned_user, :resource])
    |> order_by([t], desc: t.inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns paginated tasks for a specific resource.
  """
  def list_resource_tasks_paginated(resource_id, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 10)
    offset = (page - 1) * per_page

    tasks = Task
    |> where([t], t.resource_id == ^resource_id)
    |> preload([:assigned_user, :resource])
    |> order_by([t], desc: t.inserted_at)
    |> limit(^per_page)
    |> offset(^offset)
    |> Repo.all()

    total_count = Task
    |> where([t], t.resource_id == ^resource_id)
    |> Repo.aggregate(:count, :id)

    total_pages = ceil(total_count / per_page)

    %{
      tasks: tasks,
      page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: total_pages,
      has_next: page < total_pages,
      has_prev: page > 1
    }
  end

  @doc """
  Returns all tasks (admin view).
  """
  def list_all_tasks do
    Task
    |> preload([:assigned_user, :resource])
    |> order_by([t], desc: t.inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns paginated tasks for admin (all tasks) or user (user tasks).
  """
  def list_tasks_paginated(user, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 10)
    search_task_id = Keyword.get(opts, :search_task_id, nil)
    tab = Keyword.get(opts, :tab, "all")
    offset = (page - 1) * per_page

    base_query = cond do
      user.role == "admin" && tab == "my" ->
        Task |> where([t], t.assigned_user_id == ^user.id)
      user.role == "admin" && tab == "all" ->
        Task
      true ->
        Task |> where([t], t.assigned_user_id == ^user.id)
    end

    query = base_query
    |> preload([:assigned_user, :resource])
    |> order_by([t], desc: t.inserted_at)

    # Add search filter if provided
    query = if search_task_id && String.trim(search_task_id) != "" do
      query |> where([t], ilike(t.task_id, ^"%#{search_task_id}%"))
    else
      query
    end

    tasks = query
    |> limit(^per_page)
    |> offset(^offset)
    |> Repo.all()

    # Count query with same filters
    count_query = base_query
    count_query = if search_task_id && String.trim(search_task_id) != "" do
      count_query |> where([t], ilike(t.task_id, ^"%#{search_task_id}%"))
    else
      count_query
    end

    total_count = count_query |> Repo.aggregate(:count, :id)
    total_pages = ceil(total_count / per_page)

    %{
      tasks: tasks,
      page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: total_pages,
      has_next: page < total_pages,
      has_prev: page > 1,
      search_task_id: search_task_id
    }
  end

  @doc """
  Gets a single task.
  """
  def get_task!(id) do
    Task
    |> preload([:assigned_user, :resource, :time_logs])
    |> Repo.get!(id)
  end

  @doc """
  Gets a task by its task_id.
  """
  def get_task_by_task_id(task_id) do
    Task
    |> where([t], t.task_id == ^task_id)
    |> preload([:assigned_user, :resource, :time_logs])
    |> Repo.one()
  end

  @doc """
  Creates a task for a specific resource and user.
  """
  def create_task(attrs, user_id, resource_id) do
    %Task{}
    |> Task.changeset(Map.merge(attrs, %{
      "assigned_user_id" => user_id,
      "resource_id" => resource_id
    }))
    |> Repo.insert()
  end

  @doc """
  Updates a task.
  """
  def update_task(%Task{} = task, attrs) do
    task
    |> Task.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a task.
  """
  def delete_task(%Task{} = task) do
    Repo.delete(task)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task changes.
  """
  def change_task(%Task{} = task, attrs \\ %{}) do
    Task.changeset(task, attrs)
  end

  @doc """
  Starts a task (changes status to in_progress).
  """
  def start_task(%Task{} = task) do
    if Task.pending?(task) do
      task
      |> Task.start_changeset()
      |> Repo.update()
    else
      {:error, :task_not_pending}
    end
  end

  @doc """
  Completes a task (changes status to completed).
  """
  def complete_task(%Task{} = task) do
    if Task.in_progress?(task) do
      task
      |> Task.complete_changeset()
      |> Repo.update()
    else
      {:error, :task_not_in_progress}
    end
  end

  @doc """
  Cancels a task.
  """
  def cancel_task(%Task{} = task) do
    if not Task.completed?(task) do
      task
      |> Task.cancel_changeset()
      |> Repo.update()
    else
      {:error, :task_already_completed}
    end
  end

  @doc """
  Gets current active task for a user.
  """
  def get_active_task_for_user(user_id) do
    Task
    |> where([t], t.assigned_user_id == ^user_id and t.status == "in_progress")
    |> preload([:assigned_user, :resource, :time_logs])
    |> Repo.one()
  end

  @doc """
  Checks if user can create a new task (must have an assigned resource).
  """
  def can_create_task?(user_id) do
    user_resources = Resources.get_user_resources(user_id)
    length(user_resources) > 0
  end

  @doc """
  Gets available resources for a user to create tasks.
  """
  def get_available_resources_for_user(user_id) do
    Resources.get_user_resources(user_id)
  end

  @doc """
  Marks multiple tasks as paid.
  """
  def mark_tasks_as_paid(task_ids) when is_list(task_ids) do
    {count, _} = Task
    |> where([t], t.id in ^task_ids)
    |> where([t], t.paid == false)
    |> Repo.update_all(set: [paid: true, updated_at: DateTime.utc_now()])

    {:ok, count}
  rescue
    _ -> {:error, :update_failed}
  end

  @doc """
  Exports tasks as CSV in Google Sheets format.
  """
  def export_tasks_as_csv(task_ids) when is_list(task_ids) do
    tasks = Task
    |> where([t], t.id in ^task_ids)
    |> preload([:assigned_user, :resource])
    |> Repo.all()

    # Create CSV header
    headers = [
      "Task ID",
      "Resource Name",
      "User Name",
      "User Email",
      "Status",
      "Rate per Hour",
      "Audio Length (min)",
      "Task Value ($)",
      "Start Date",
      "Finish Date",
      "Created Date",
      "Paid Status"
    ]

    # Convert tasks to CSV rows
    rows = Enum.map(tasks, fn task ->
      [
        task.task_id,
        task.resource.name,
        if(task.assigned_user, do: task.assigned_user.name, else: ""),
        if(task.assigned_user, do: task.assigned_user.email, else: ""),
        String.capitalize(task.status),
        format_decimal_for_sheets(task.rate_per_hour),
        if(task.audio_length_minutes, do: format_decimal_for_sheets(task.audio_length_minutes), else: "0"),
        format_decimal_for_sheets(task.task_value_dollars),
        if(task.start_datetime, do: NaiveDateTime.to_string(task.start_datetime), else: ""),
        if(task.finished_at, do: NaiveDateTime.to_string(task.finished_at), else: ""),
        DateTime.to_string(task.inserted_at),
        if(task.paid, do: "Paid", else: "Unpaid")
      ]
    end)

    # Combine headers and rows
    csv_data = [headers | rows]

    # Convert to CSV format
    csv_content = csv_data
    |> Enum.map(fn row ->
      row
      |> Enum.map(&escape_csv_field/1)
      |> Enum.join(",")
    end)
    |> Enum.join("\n")

    {:ok, csv_content}
  rescue
    _ -> {:error, :export_failed}
  end

  # Helper function to format decimal numbers for Google Sheets (comma as decimal separator)
  defp format_decimal_for_sheets(decimal) when is_nil(decimal), do: "0"
  defp format_decimal_for_sheets(decimal) do
    decimal
    |> Decimal.to_string()
    |> String.replace(".", ",")
  end

  # Helper function to escape CSV fields
  defp escape_csv_field(field) when is_binary(field) do
    if String.contains?(field, [",", "\"", "\n", "\r"]) do
      "\"" <> String.replace(field, "\"", "\"\"") <> "\""
    else
      field
    end
  end

  defp escape_csv_field(field), do: to_string(field)
end