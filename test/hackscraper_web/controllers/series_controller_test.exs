defmodule HackScraperWeb.SeriesControllerTest do
  use HackScraperWeb.ConnCase

  import HackScraper.EventsFixtures

  @create_attrs %{name: "some name", description: "some description"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil, description: nil}

  describe "index" do
    test "lists all series", %{conn: conn} do
      conn = get(conn, ~p"/series")
      assert html_response(conn, 200) =~ "Listing Series"
    end
  end

  describe "new series" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/series/new")
      assert html_response(conn, 200) =~ "New Series"
    end
  end

  describe "create series" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/series", series: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/series/#{id}"

      conn = get(conn, ~p"/series/#{id}")
      assert html_response(conn, 200) =~ "Series #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/series", series: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Series"
    end
  end

  describe "edit series" do
    setup [:create_series]

    test "renders form for editing chosen series", %{conn: conn, series: series} do
      conn = get(conn, ~p"/series/#{series}/edit")
      assert html_response(conn, 200) =~ "Edit Series"
    end
  end

  describe "update series" do
    setup [:create_series]

    test "redirects when data is valid", %{conn: conn, series: series} do
      conn = put(conn, ~p"/series/#{series}", series: @update_attrs)
      assert redirected_to(conn) == ~p"/series/#{series}"

      conn = get(conn, ~p"/series/#{series}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, series: series} do
      conn = put(conn, ~p"/series/#{series}", series: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Series"
    end
  end

  describe "delete series" do
    setup [:create_series]

    test "deletes chosen series", %{conn: conn, series: series} do
      conn = delete(conn, ~p"/series/#{series}")
      assert redirected_to(conn) == ~p"/series"

      assert_error_sent 404, fn ->
        get(conn, ~p"/series/#{series}")
      end
    end
  end

  defp create_series(_) do
    series = series_fixture()
    %{series: series}
  end
end
