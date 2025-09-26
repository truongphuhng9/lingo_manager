defmodule LingoManagerWeb.ResourceController do
  use LingoManagerWeb, :controller

  alias LingoManager.Resources
  alias LingoManager.Resources.Resource

  def index(conn, params) do
    page = String.to_integer(params["page"] || "1")
    pagination = Resources.list_resources(page: page, per_page: 10)
    render(conn, :index, pagination: pagination)
  end

  def show(conn, %{"id" => id} = params) do
    resource = Resources.get_resource!(id)
    page = String.to_integer(params["page"] || "1")
    per_page = String.to_integer(params["per_page"] || "10")

    tasks_pagination = LingoManager.Tasks.list_resource_tasks_paginated(id, page: page, per_page: per_page)

    render(conn, :show, resource: resource, tasks_pagination: tasks_pagination, per_page: per_page)
  end

  def new(conn, _params) do
    current_user = conn.assigns.current_user
    if current_user.role == "admin" do
      changeset = Resources.change_resource(%Resource{})
      render(conn, :new, changeset: changeset)
    else
      conn
      |> put_flash(:error, "Only admins can create resources.")
      |> redirect(to: ~p"/resources")
    end
  end

  def create(conn, %{"resource" => resource_params}) do
    current_user = conn.assigns.current_user
    if current_user.role == "admin" do
      case Resources.create_resource(resource_params) do
        {:ok, resource} ->
          conn
          |> put_flash(:info, "Resource created successfully.")
          |> redirect(to: ~p"/resources/#{resource}")

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, :new, changeset: changeset)
      end
    else
      conn
      |> put_flash(:error, "Only admins can create resources.")
      |> redirect(to: ~p"/resources")
    end
  end

  def edit(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user
    if current_user.role == "admin" do
      resource = Resources.get_resource!(id)
      changeset = Resources.change_resource(resource)
      render(conn, :edit, resource: resource, changeset: changeset)
    else
      conn
      |> put_flash(:error, "Only admins can edit resources.")
      |> redirect(to: ~p"/resources")
    end
  end

  def update(conn, %{"id" => id, "resource" => resource_params}) do
    current_user = conn.assigns.current_user
    if current_user.role == "admin" do
      resource = Resources.get_resource!(id)

      case Resources.update_resource(resource, resource_params) do
        {:ok, resource} ->
          conn
          |> put_flash(:info, "Resource updated successfully.")
          |> redirect(to: ~p"/resources/#{resource}")

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, :edit, resource: resource, changeset: changeset)
      end
    else
      conn
      |> put_flash(:error, "Only admins can edit resources.")
      |> redirect(to: ~p"/resources")
    end
  end

  def delete(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user
    if current_user.role == "admin" do
      resource = Resources.get_resource!(id)
      {:ok, _resource} = Resources.delete_resource(resource)

      conn
      |> put_flash(:info, "Resource deleted successfully.")
      |> redirect(to: ~p"/resources")
    else
      conn
      |> put_flash(:error, "Only admins can delete resources.")
      |> redirect(to: ~p"/resources")
    end
  end

  def assign_to_user(conn, %{"id" => id}) do
    resource = Resources.get_resource!(id)
    current_user = conn.assigns.current_user

    case Resources.mark_resource_in_use(resource, current_user.id) do
      {:ok, _resource} ->
        conn
        |> put_flash(:info, "Resource assigned to you successfully.")
        |> redirect(to: ~p"/resources")

      {:error, :resource_not_available} ->
        conn
        |> put_flash(:error, "Resource is not available.")
        |> redirect(to: ~p"/resources")
    end
  end

  def release_from_user(conn, %{"id" => id}) do
    resource = Resources.get_resource!(id)

    case Resources.mark_resource_available(resource) do
      {:ok, _resource} ->
        conn
        |> put_flash(:info, "Resource released successfully.")
        |> redirect(to: ~p"/resources")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to release resource.")
        |> redirect(to: ~p"/resources")
    end
  end

  def mark_tasks_paid(conn, %{"id" => id, "task_ids" => task_ids}) do
    current_user = conn.assigns.current_user

    if current_user.role == "admin" do
      case LingoManager.Tasks.mark_tasks_as_paid(task_ids) do
        {:ok, count} ->
          conn
          |> put_flash(:info, "Successfully marked #{count} tasks as paid.")
          |> redirect(to: ~p"/resources/#{id}")

        {:error, _reason} ->
          conn
          |> put_flash(:error, "Failed to mark tasks as paid.")
          |> redirect(to: ~p"/resources/#{id}")
      end
    else
      conn
      |> put_flash(:error, "Only admins can mark tasks as paid.")
      |> redirect(to: ~p"/resources")
    end
  end

  def export_tasks(conn, %{"id" => id, "task_ids" => task_ids}) do
    current_user = conn.assigns.current_user

    if current_user.role == "admin" do
      case LingoManager.Tasks.export_tasks_as_csv(task_ids) do
        {:ok, csv_content} ->
          resource = Resources.get_resource!(id)
          filename = "tasks_#{resource.name}_#{Date.to_string(Date.utc_today())}.csv"

          conn
          |> put_resp_content_type("text/csv")
          |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
          |> send_resp(200, csv_content)

        {:error, _reason} ->
          conn
          |> put_flash(:error, "Failed to export tasks.")
          |> redirect(to: ~p"/resources/#{id}")
      end
    else
      conn
      |> put_flash(:error, "Only admins can export tasks.")
      |> redirect(to: ~p"/resources")
    end
  end
end