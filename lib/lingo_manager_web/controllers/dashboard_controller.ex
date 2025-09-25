defmodule LingoManagerWeb.DashboardController do
  use LingoManagerWeb, :controller

  def index(conn, _params) do
    current_user = conn.assigns.current_user
    render(conn, :index, current_user: current_user)
  end
end