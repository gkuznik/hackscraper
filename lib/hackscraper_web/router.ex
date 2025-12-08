defmodule HackScraperWeb.Router do
  use HackScraperWeb, :router

  import HackScraperWeb.UserAuth
  import Phoenix.LiveDashboard.Router
  import Oban.Web.Router

  def role_only(conn, %{role: role}) do
    if HackScraper.Accounts.can_do?(conn.assigns[:current_user], role) do
      conn
    else
      conn
      |> put_flash(:error, "You are not authorized to access this page.")
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

  pipeline :editor do
    plug :require_authenticated_user
    plug :role_only, %{role: :editor}
  end

  pipeline :mod do
    plug :require_authenticated_user
    plug :role_only, %{role: :mod}
  end

  pipeline :admin do
    plug :require_authenticated_user
    plug :role_only, %{role: :admin}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HackScraperWeb do
    pipe_through [:browser, :editor]

    live "/series/new", SeriesLive.Index, :new
    live "/series/:id/edit", SeriesLive.Index, :edit
    live "/series/:id/show/edit", SeriesLive.Show, :edit

    live "/suggestions/:id/review", SuggestionLive.Index, :review
    live "/suggestions/:id/show/review", SuggestionLive.Show, :review
  end

  scope "/", HackScraperWeb do
    pipe_through [:browser, :require_authenticated_user]

    live "/suggestions", SuggestionLive.Index, :index
    live "/suggestions/:id", SuggestionLive.Show, :show
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
    live "/series/:id", SeriesLive.Show, :show
  end

  scope "/", HackScraperWeb do
    pipe_through [:browser, :mod]

    live "/users", UserLive.Index, :index
    live "/users/new", UserLive.Index, :new
    live "/users/:id/edit", UserLive.Index, :edit
    live "/users/:id", UserLive.Show, :show
    live "/users/:id/show/edit", UserLive.Show, :edit
  end

  scope "/" do
    pipe_through [:browser, :admin]

    if Application.compile_env(:hackscraper, :dev_routes) do
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end

    live_dashboard "/dashboard", metrics: HackScraperWeb.Telemetry
    oban_dashboard("/oban", logo_path: "/")

    alias HackScraperWeb.ScraperLive
    live "/scrapers", ScraperLive.Index, :index
    live "/scrapers/new", ScraperLive.Index, :new
    live "/scrapers/:id/edit", ScraperLive.Index, :edit
    live "/scrapers/:id", ScraperLive.Show, :show
    live "/scrapers/:id/show/edit", ScraperLive.Show, :edit
  end

  ## Authentication routes

  scope "/", HackScraperWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{HackScraperWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/user/register", UserRegistrationLive, :new
      live "/user/log_in", UserLoginLive, :new
      live "/user/reset_password", UserForgotPasswordLive, :new
      live "/user/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/user/log_in", UserSessionController, :create
  end

  scope "/", HackScraperWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{HackScraperWeb.UserAuth, :ensure_authenticated}] do
      live "/user/settings", UserSettingsLive, :edit
      live "/user/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", HackScraperWeb do
    pipe_through [:browser]

    delete "/user/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{HackScraperWeb.UserAuth, :mount_current_user}] do
      live "/user/confirm/:token", UserConfirmationLive, :edit
      live "/user/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
