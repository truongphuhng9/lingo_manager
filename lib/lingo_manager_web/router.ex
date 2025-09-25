defmodule LingoManagerWeb.Router do
  use LingoManagerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LingoManagerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug LingoManagerWeb.Auth, :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :require_authenticated_user do
    plug LingoManagerWeb.Auth, :require_authenticated_user
  end

  pipeline :require_admin_user do
    plug LingoManagerWeb.Auth, :require_admin_user
  end

  scope "/", LingoManagerWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    delete "/users/log_out", UserSessionController, :delete
  end

  scope "/", LingoManagerWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/dashboard", DashboardController, :index
    resources "/resources", ResourceController
    post "/resources/:id/assign", ResourceController, :assign_to_user
    delete "/resources/:id/release", ResourceController, :release_from_user
    post "/resources/:id/mark_tasks_paid", ResourceController, :mark_tasks_paid
    get "/resources/:id/export_tasks", ResourceController, :export_tasks

    resources "/tasks", TaskController, only: [:index, :show, :new, :create, :edit, :update]
    post "/tasks/:id/start", TaskController, :start_task
    post "/tasks/:id/complete", TaskController, :complete_task
    post "/tasks/:id/start_time_log", TaskController, :start_time_log
    post "/tasks/stop_time_log", TaskController, :stop_time_log
  end

  scope "/admin", LingoManagerWeb do
    pipe_through [:browser, :require_authenticated_user, :require_admin_user]

    get "/", AdminController, :index
    resources "/users", AdminUserController
  end

  # Other scopes may use custom stacks.
  # scope "/api", LingoManagerWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:lingo_manager, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LingoManagerWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
