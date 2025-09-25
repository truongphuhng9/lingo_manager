defmodule LingoManagerWeb.TaskController do
  use LingoManagerWeb, :controller

  alias LingoManager.Tasks
  alias LingoManager.Tasks.Task
  alias LingoManager.TimeLogs
  alias LingoManager.Resources

  def index(conn, params) do
    current_user = conn.assigns.current_user
    page = String.to_integer(params["page"] || "1")

    tasks_pagination = Tasks.list_user_tasks_paginated(current_user.id, page: page, per_page: 10)
    active_task = Tasks.get_active_task_for_user(current_user.id)
    active_time_log = if active_task, do: TimeLogs.get_active_time_log_for_user(current_user.id), else: nil

    render(conn, :index,
      tasks_pagination: tasks_pagination,
      active_task: active_task,
      active_time_log: active_time_log,
      can_create_task: Tasks.can_create_task?(current_user.id)
    )
  end

  def show(conn, %{"id" => id}) do
    task = Tasks.get_task!(id)
    current_user = conn.assigns.current_user

    # Only allow users to see their own tasks or admins to see all
    if task.assigned_user_id == current_user.id || current_user.role == "admin" do
      time_logs = TimeLogs.list_task_time_logs(task.id)
      render(conn, :show, task: task, time_logs: time_logs)
    else
      conn
      |> put_flash(:error, "Access denied.")
      |> redirect(to: ~p"/tasks")
    end
  end

  def new(conn, %{"resource_id" => resource_id}) do
    current_user = conn.assigns.current_user
    resource = Resources.get_resource!(resource_id)

    # Verify user owns this resource
    if resource.current_user_id == current_user.id do
      changeset = Tasks.change_task(%Task{})
      render(conn, :new, changeset: changeset, resource: resource)
    else
      conn
      |> put_flash(:error, "You can only create tasks for resources you are currently using.")
      |> redirect(to: ~p"/resources")
    end
  end

  def new(conn, _params) do
    current_user = conn.assigns.current_user
    available_resources = Tasks.get_available_resources_for_user(current_user.id)

    if length(available_resources) == 0 do
      conn
      |> put_flash(:error, "You need to assign yourself to a resource before creating tasks.")
      |> redirect(to: ~p"/resources")
    else
      render(conn, :select_resource, resources: available_resources)
    end
  end

  def create(conn, %{"task" => task_params, "resource_id" => resource_id}) do
    current_user = conn.assigns.current_user
    resource = Resources.get_resource!(resource_id)

    # Verify user owns this resource
    if resource.current_user_id == current_user.id do
      case Tasks.create_task(task_params, current_user.id, resource_id) do
        {:ok, task} ->
          conn
          |> put_flash(:info, "Task created successfully.")
          |> redirect(to: ~p"/tasks/#{task}")

        {:error, %Ecto.Changeset{} = changeset} ->
          IO.inspect(changeset)
          render(conn, :new, changeset: changeset, resource: resource)
      end
    else
      conn
      |> put_flash(:error, "You can only create tasks for resources you are currently using.")
      |> redirect(to: ~p"/resources")
    end
  end

  def start_task(conn, %{"id" => id}) do
    task = Tasks.get_task!(id)
    current_user = conn.assigns.current_user

    if task.assigned_user_id == current_user.id do
      case Tasks.start_task(task) do
        {:ok, _task} ->
          conn
          |> put_flash(:info, "Task started successfully.")
          |> redirect(to: ~p"/tasks")

        {:error, :task_not_pending} ->
          conn
          |> put_flash(:error, "Task is not in pending status.")
          |> redirect(to: ~p"/tasks")
      end
    else
      conn
      |> put_flash(:error, "Access denied.")
      |> redirect(to: ~p"/tasks")
    end
  end

  def complete_task(conn, %{"id" => id}) do
    task = Tasks.get_task!(id)
    current_user = conn.assigns.current_user

    if task.assigned_user_id == current_user.id do
      # End any active time log first
      active_time_log = TimeLogs.get_active_time_log_for_user(current_user.id)
      if active_time_log do
        TimeLogs.end_time_log(active_time_log)
      end

      case Tasks.complete_task(task) do
        {:ok, _task} ->
          conn
          |> put_flash(:info, "Task completed successfully!")
          |> redirect(to: ~p"/tasks")

        {:error, :task_not_in_progress} ->
          conn
          |> put_flash(:error, "Task is not in progress.")
          |> redirect(to: ~p"/tasks")
      end
    else
      conn
      |> put_flash(:error, "Access denied.")
      |> redirect(to: ~p"/tasks")
    end
  end

  def start_time_log(conn, %{"id" => id}) do
    task = Tasks.get_task!(id)
    current_user = conn.assigns.current_user

    if task.assigned_user_id == current_user.id do
      # Check if user already has an active time log
      if TimeLogs.get_active_time_log_for_user(current_user.id) do
        conn
        |> put_flash(:error, "You already have an active time log. Please stop it first.")
        |> redirect(to: ~p"/tasks")
      else
        case TimeLogs.start_time_log(%{user_id: current_user.id, task_id: task.id}) do
          {:ok, _time_log} ->
            # Start the task if it's pending
            if Task.pending?(task) do
              Tasks.start_task(task)
            end

            conn
            |> put_flash(:info, "Time logging started.")
            |> redirect(to: ~p"/tasks")

          {:error, _changeset} ->
            conn
            |> put_flash(:error, "Failed to start time logging.")
            |> redirect(to: ~p"/tasks")
        end
      end
    else
      conn
      |> put_flash(:error, "Access denied.")
      |> redirect(to: ~p"/tasks")
    end
  end

  def stop_time_log(conn, _params) do
    current_user = conn.assigns.current_user
    active_time_log = TimeLogs.get_active_time_log_for_user(current_user.id)

    if active_time_log do
      case TimeLogs.end_time_log(active_time_log) do
        {:ok, _time_log} ->
          conn
          |> put_flash(:info, "Time logging stopped.")
          |> redirect(to: ~p"/tasks")

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Failed to stop time logging.")
          |> redirect(to: ~p"/tasks")
      end
    else
      conn
      |> put_flash(:error, "No active time log found.")
      |> redirect(to: ~p"/tasks")
    end
  end

  def edit(conn, %{"id" => id}) do
    task = Tasks.get_task!(id)
    current_user = conn.assigns.current_user

    # Only allow task owner or admin to edit
    if task.assigned_user_id == current_user.id || current_user.role == "admin" do
      changeset = Tasks.change_task(task)
      resource = Resources.get_resource!(task.resource_id)
      users = if current_user.role == "admin", do: LingoManager.Accounts.list_users(), else: []
      render(conn, :edit, task: task, changeset: changeset, resource: resource, users: users)
    else
      conn
      |> put_flash(:error, "Access denied.")
      |> redirect(to: ~p"/tasks")
    end
  end

  def update(conn, %{"id" => id, "task" => task_params}) do
    task = Tasks.get_task!(id)
    current_user = conn.assigns.current_user

    # Only allow task owner or admin to edit
    if task.assigned_user_id == current_user.id || current_user.role == "admin" do
      case Tasks.update_task(task, task_params) do
        {:ok, task} ->
          conn
          |> put_flash(:info, "Task updated successfully.")
          |> redirect(to: ~p"/tasks/#{task}")

        {:error, %Ecto.Changeset{} = changeset} ->
          resource = Resources.get_resource!(task.resource_id)
          users = if current_user.role == "admin", do: LingoManager.Accounts.list_users(), else: []
          render(conn, :edit, task: task, changeset: changeset, resource: resource, users: users)
      end
    else
      conn
      |> put_flash(:error, "Access denied.")
      |> redirect(to: ~p"/tasks")
    end
  end
end
