defmodule HackScraperWeb.ScraperLiveTest do
  use HackScraperWeb.ConnCase

  import Phoenix.LiveViewTest
  import HackScraper.ScrapersFixtures
  import HackScraper.AccountsFixtures

  @create_attrs %{
    name: "some name",
    worker: "Dummy",
    url: "some url",
    schedule: "@daily",
    paused: true
  }
  @update_attrs %{
    name: "some updated name",
    worker: "Devpost",
    url: "some updated url",
    schedule: "@hourly",
    paused: false
  }
  @invalid_attrs %{name: nil, worker: "Dummy", url: nil, schedule: nil, paused: false}

  defp create_scraper(_) do
    scraper = scraper_fixture()
    %{scraper: scraper}
  end

  describe "Index" do
    setup [:create_scraper]

    test "lists all scrapers", %{conn: conn, scraper: scraper} do
      {:ok, _index_live, html} =
        conn |> log_in_user(user_fixture(%{role: :admin})) |> live(~p"/scrapers")

      assert html =~ "Listing Scrapers"
      assert html =~ scraper.worker
    end

    test "saves new scraper", %{conn: conn} do
      {:ok, index_live, _html} =
        conn |> log_in_user(user_fixture(%{role: :admin})) |> live(~p"/scrapers")

      assert index_live |> element("a", "New Scraper") |> render_click() =~
               "New Scraper"

      assert_patch(index_live, ~p"/scrapers/new")

      assert index_live
             |> form("#scraper-form", scheduled: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#scraper-form", scheduled: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/scrapers")

      html = render(index_live)
      assert html =~ "Scraper created successfully"
      assert html =~ "Dummy"
    end

    test "updates scraper in listing", %{conn: conn, scraper: scraper} do
      {:ok, index_live, _html} =
        conn |> log_in_user(user_fixture(%{role: :admin})) |> live(~p"/scrapers")

      assert index_live |> element("#scrapers-#{scraper.id} a", "Edit") |> render_click() =~
               "Edit Scraper"

      assert_patch(index_live, ~p"/scrapers/#{scraper}/edit")

      assert index_live
             |> form("#scraper-form", scheduled: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#scraper-form", scheduled: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/scrapers")

      html = render(index_live)
      assert html =~ "Scraper updated successfully"
      assert html =~ "Devpost"
    end

    test "deletes scraper in listing", %{conn: conn, scraper: scraper} do
      {:ok, index_live, _html} =
        conn |> log_in_user(user_fixture(%{role: :admin})) |> live(~p"/scrapers")

      assert index_live |> element("#scrapers-#{scraper.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#scrapers-#{scraper.id}")
    end
  end

  describe "Show" do
    setup [:create_scraper]

    test "displays scraper", %{conn: conn, scraper: scraper} do
      {:ok, _show_live, html} =
        conn |> log_in_user(user_fixture(%{role: :admin})) |> live(~p"/scrapers/#{scraper}")

      assert html =~ "Scraper: "
      assert html =~ scraper.worker
    end

    test "updates scraper within modal", %{conn: conn, scraper: scraper} do
      {:ok, show_live, _html} =
        conn |> log_in_user(user_fixture(%{role: :admin})) |> live(~p"/scrapers/#{scraper}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit "

      assert_patch(show_live, ~p"/scrapers/#{scraper}/show/edit")

      assert show_live
             |> form("#scraper-form", scheduled: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#scraper-form", scheduled: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/scrapers/#{scraper}")

      html = render(show_live)
      assert html =~ "Scraper updated successfully"
      assert html =~ "Devpost"
    end
  end
end
