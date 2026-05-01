defmodule HairZippikerWeb.Router do
  use HairZippikerWeb, :router

  import HairZippikerWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HairZippikerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", HairZippikerWeb do
    pipe_through :api

    post "/mpesa/callback", PageController, :mpesa_callback
  end

  # --- MAIN CUSTOMER ENTRY ---
  scope "/", HairZippikerWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/book", PageController, :book
    post "/book", PageController, :confirm_booking
    post "/mpesa/stk_push", PageController, :initiate_stk_push
    get "/shop", PageController, :shop
    post "/enter_salon", PageController, :enter_salon
    delete "/exit_salon", PageController, :exit_salon
  end

  # --- AUTHENTICATED ROUTES ---
  scope "/", HairZippikerWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{HairZippikerWeb.UserAuth, :require_authenticated}] do
      live "/admin/dashboard", AdminDashboardLive, :index
      live "/admin/employees", AdminEmployeesLive, :index
      live "/employer/portal", EmployerDashboardLive, :index
      live "/admin/staff", AdminStaffLive, :index
      live "/admin/inventory", AdminInventoryLive, :index

      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
      live "/admin/profile", AdminDashboardLive, :profile
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  # --- PUBLIC AUTH ROUTES ---
  scope "/", HairZippikerWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{HairZippikerWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/reset-password", UserForgotPasswordLive, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
