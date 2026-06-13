defmodule HackScraperWeb.UserRegistrationToggleTest do
  use HackScraperWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  alias HackScraper.Accounts

  setup do
    initial_config = Application.get_env(:hackscraper, :registration)

    on_exit(fn ->
      Application.put_env(:hackscraper, :registration, initial_config)
    end)

    :ok
  end

  describe "when registration is enabled" do
    setup do
      Application.put_env(:hackscraper, :registration, enabled: true)
      :ok
    end

    test "allows visiting the registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/user/register")
      assert html =~ "Register"
    end

    test "shows register link on login page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/user/log_in")
      assert html =~ "Sign up"
    end
  end

  describe "when registration is disabled" do
    setup do
      Application.put_env(:hackscraper, :registration, enabled: false)
      :ok
    end

    test "redirects registration page to home page", %{conn: conn} do
      conn = get(conn, ~p"/user/register")
      assert redirected_to(conn) == ~p"/"

      # Follow redirect to see flash message
      conn = get(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Registration is currently disabled."
    end

    test "does not show register links on home, about, login and forgot password pages", %{
      conn: conn
    } do
      # Login page doesn't show signup
      {:ok, _lv, html} = live(conn, ~p"/user/log_in")
      refute html =~ "Sign up"
      refute html =~ ~p"/user/register"

      # Forgot password page
      {:ok, _lv, html} = live(conn, ~p"/user/reset_password")
      refute html =~ "Register"

      # Home page
      conn_home = get(conn, ~p"/")
      html_home = html_response(conn_home, 200)
      refute html_home =~ "Register"

      # About page
      conn_about = get(conn, ~p"/about")
      html_about = html_response(conn_about, 200)
      refute html_about =~ "Register"
    end

    test "register_user/1 returns error changeset", _context do
      {:error, changeset} =
        Accounts.register_user(%{email: "test@example.com", password: "Password123!"})

      assert %{email: ["registration is currently disabled"]} =
               HackScraper.DataCase.errors_on(changeset)
    end
  end
end
