defmodule HackScraperWeb.ScraperLiveTest do
  use HackScraperWeb.ConnCase

  import Phoenix.LiveViewTest
  import HackScraper.ScrapersFixtures

  @create_attrs %{worker: "some worker", url: "some url", schedule: "some schedule", paused: true}
  @update_attrs %{worker: "some updated worker", url: "some updated url", schedule: "some updated schedule", paused: false}
  @invalid_attrs %{worker: nil, url: nil, schedule: nil, paused: false}

  defp create_scraper(_) do
    scraper = scraper_fixture()
    %{scraper: scraper}
  end

  describe "Index" do
    setup [:create_scraper]

    test "lists all scrapers", %{conn: conn, scraper: scraper} do
      {:ok, _index_live, html} = live(conn, ~p"/scrapers")

      assert html =~ "Listing Scrapers"
      assert html =~ scraper.worker
    end

    test "saves new scraper", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/scrapers")

      assert index_live |> element("a", "New Scraper") |> render_click() =~
               "New Scraper"

      assert_patch(index_live, ~p"/scrapers/new")

      assert index_live
             |> form("#scraper-form", scraper: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#scraper-form", scraper: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/scrapers")

      html = render(index_live)
      assert html =~ "Scraper created successfully"
      assert html =~ "some worker"
    end

    test "updates scraper in listing", %{conn: conn, scraper: scraper} do
      {:ok, index_live, _html} = live(conn, ~p"/scrapers")

      assert index_live |> element("#scrapers-#{scraper.id} a", "Edit") |> render_click() =~
               "Edit Scraper"

      assert_patch(index_live, ~p"/scrapers/#{scraper}/edit")

      assert index_live
             |> form("#scraper-form", scraper: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#scraper-form", scraper: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/scrapers")

      html = render(index_live)
      assert html =~ "Scraper updated successfully"
      assert html =~ "some updated worker"
    end

    test "deletes scraper in listing", %{conn: conn, scraper: scraper} do
      {:ok, index_live, _html} = live(conn, ~p"/scrapers")

      assert index_live |> element("#scrapers-#{scraper.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#scrapers-#{scraper.id}")
    end
  end

  describe "Show" do
    setup [:create_scraper]

    test "displays scraper", %{conn: conn, scraper: scraper} do
      {:ok, _show_live, html} = live(conn, ~p"/scrapers/#{scraper}")

      assert html =~ "Show Scraper"
      assert html =~ scraper.worker
    end

    test "updates scraper within modal", %{conn: conn, scraper: scraper} do
      {:ok, show_live, _html} = live(conn, ~p"/scrapers/#{scraper}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Scraper"

      assert_patch(show_live, ~p"/scrapers/#{scraper}/show/edit")

      assert show_live
             |> form("#scraper-form", scraper: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#scraper-form", scraper: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/scrapers/#{scraper}")

      html = render(show_live)
      assert html =~ "Scraper updated successfully"
      assert html =~ "some updated worker"
    end
  end
end
