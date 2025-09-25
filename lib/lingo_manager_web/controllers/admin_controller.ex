defmodule LingoManagerWeb.AdminController do
  use LingoManagerWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end