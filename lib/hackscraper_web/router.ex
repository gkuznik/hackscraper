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
    pipe_through [:browser, :require_authenticated_user]

    resources "/hackathons", HackathonController, except: [:index, :show]
    resources "/series", SeriesController, except: [:index, :show]
  end
  scope "/", HackScraperWeb do
    pipe_through :browser

    get "/", PageController, :home
    resources "/hackathons", HackathonController, only: [:index, :show]
    resources "/series", SeriesController, only: [:index, :show]
  end


  scope "/" do
    if Application.compile_env(:hackscraper, :dev_routes) do
      pipe_through [:browser]
    else
      pipe_through [:browser, :require_authenticated_user, :admin_only]
    end

    live_dashboard "/dashboard", metrics: HackScraperWeb.Telemetry
    oban_dashboard "/oban"

    if Application.compile_env(:hackscraper, :dev_routes) do
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", HackScraperWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", HackScraperWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", HackScraperWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end
end
