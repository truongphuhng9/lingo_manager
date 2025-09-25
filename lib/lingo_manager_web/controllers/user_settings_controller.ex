defmodule LingoManagerWeb.UserSettingsController do
  use LingoManagerWeb, :controller

  alias LingoManager.Accounts

  def show(conn, _params) do
    user = conn.assigns.current_user
    changeset = Accounts.change_user_password(user)
    render(conn, :show, changeset: changeset)
  end

  def update_password(conn, %{"user" => user_params}) do
    %{"current_password" => password, "password" => new_password} = user_params
    user = conn.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> redirect(to: ~p"/settings")

      {:error, changeset} ->
        render(conn, :show, changeset: changeset)
    end
  end
end