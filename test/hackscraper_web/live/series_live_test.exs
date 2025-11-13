defmodule HackScraperWeb.SeriesLiveTest do
  use HackScraperWeb.ConnCase

  import Phoenix.LiveViewTest
  import HackScraper.EventsFixtures

  @create_attrs %{name: "some name", description: "some description", image: "some image", url: "some url"}
  @update_attrs %{name: "some updated name", description: "some updated description", image: "some updated image", url: "some updated url"}
  @invalid_attrs %{name: nil, description: nil, image: nil, url: nil}

  defp create_series(_) do
    series = series_fixture()
    %{series: series}
  end

  describe "Index" do
    setup [:create_series]

    test "lists all series", %{conn: conn, series: series} do
      {:ok, _index_live, html} = live(conn, ~p"/series")

      assert html =~ "Listing Series"
      assert html =~ series.name
    end

    test "saves new series", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/series")

      assert index_live |> element("a", "New Series") |> render_click() =~
               "New Series"

      assert_patch(index_live, ~p"/series/new")

      assert index_live
             |> form("#series-form", series: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#series-form", series: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/series")

      html = render(index_live)
      assert html =~ "Series created successfully"
      assert html =~ "some name"
    end

    test "updates series in listing", %{conn: conn, series: series} do
      {:ok, index_live, _html} = live(conn, ~p"/series")

      assert index_live |> element("#series-#{series.id} a", "Edit") |> render_click() =~
               "Edit Series"

      assert_patch(index_live, ~p"/series/#{series}/edit")

      assert index_live
             |> form("#series-form", series: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#series-form", series: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/series")

      html = render(index_live)
      assert html =~ "Series updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes series in listing", %{conn: conn, series: series} do
      {:ok, index_live, _html} = live(conn, ~p"/series")

      assert index_live |> element("#series-#{series.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#series-#{series.id}")
    end
  end

  describe "Show" do
    setup [:create_series]

    test "displays series", %{conn: conn, series: series} do
      {:ok, _show_live, html} = live(conn, ~p"/series/#{series}")

      assert html =~ "Show Series"
      assert html =~ series.name
    end

    test "updates series within modal", %{conn: conn, series: series} do
      {:ok, show_live, _html} = live(conn, ~p"/series/#{series}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Series"

      assert_patch(show_live, ~p"/series/#{series}/show/edit")

      assert show_live
             |> form("#series-form", series: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#series-form", series: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/series/#{series}")

      html = render(show_live)
      assert html =~ "Series updated successfully"
      assert html =~ "some updated name"
    end
  end
end
