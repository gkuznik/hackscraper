defmodule HackScraperWeb.Router do
  use HackScraperWeb, :router

  import HackScraperWeb.UserAuth
  import Phoenix.LiveDashboard.Router
  import Oban.Web.Router

  def admin_only(conn, _opts) do
    if conn.assigns[:user].is_admin do
      conn
    else
      conn
      |> put_flash(:error, "You do not have the required permissions.")
      |> redirect(to: "/")
      |> halt()
    end
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HackScraperWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HackScraperWeb do
    pipe_through :browser

    get "/", PageController, :home

    live "/hackathons", HackathonLive.Index, :index
    live "/hackathons/new", HackathonLive.Index, :new
    live "/hackathons/:id/edit", HackathonLive.Index, :edit
    live "/hackathons/:id", HackathonLive.Show, :show
    live "/hackathons/:id/show/edit", HackathonLive.Show, :edit

    live "/series", SeriesLive.Index, :index
    live "/series/new", SeriesLive.Index, :new
    live "/series/:id/edit", SeriesLive.Index, :edit
    live "/series/:id", SeriesLive.Show, :show
    live "/series/:id/show/edit", SeriesLive.Show, :edit
  end

  scope "/", HackScraperWeb do
    pipe_through [:browser, :require_authenticated_user]
  end

  scope "/" do
    if Application.compile_env(:hackscraper, :dev_routes) do
      pipe_through [:browser]
    else
      pipe_through [:browser, :require_authenticated_user, :admin_only]
    end

    if Application.compile_env(:hackscraper, :dev_routes) do
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end

    alias HackScraperWeb.UserLive

    live_dashboard "/dashboard", metrics: HackScraperWeb.Telemetry
    oban_dashboard("/oban")

    live "/users", UserLive.Index, :index
    live "/users/new", UserLive.Index, :new
    live "/users/:id/edit", UserLive.Index, :edit

    live "/users/:id", UserLive.Show, :show
    live "/users/:id/show/edit", UserLive.Show, :edit
  end

  ## Authentication routes

  scope "/", HackScraperWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{HackScraperWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", HackScraperWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{HackScraperWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", HackScraperWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{HackScraperWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
