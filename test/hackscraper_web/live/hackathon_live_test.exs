defmodule HackScraperWeb.HackathonLiveTest do
  use HackScraperWeb.ConnCase

  import Phoenix.LiveViewTest
  import HackScraper.EventsFixtures

  @create_attrs %{name: "some name", description: "some description", location: "some location", image: "some image", url: "some url", start_date: "2025-11-11T23:07:00Z", end_date: "2025-11-11T23:07:00Z"}
  @update_attrs %{name: "some updated name", description: "some updated description", location: "some updated location", image: "some updated image", url: "some updated url", start_date: "2025-11-12T23:07:00Z", end_date: "2025-11-12T23:07:00Z"}
  @invalid_attrs %{name: nil, description: nil, location: nil, image: nil, url: nil, start_date: nil, end_date: nil}

  defp create_hackathon(_) do
    hackathon = hackathon_fixture()
    %{hackathon: hackathon}
  end

  describe "Index" do
    setup [:create_hackathon]

    test "lists all hackathons", %{conn: conn, hackathon: hackathon} do
      {:ok, _index_live, html} = live(conn, ~p"/hackathons")

      assert html =~ "Listing Hackathons"
      assert html =~ hackathon.name
    end

    test "saves new hackathon", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/hackathons")

      assert index_live |> element("a", "New Hackathon") |> render_click() =~
               "New Hackathon"

      assert_patch(index_live, ~p"/hackathons/new")

      assert index_live
             |> form("#hackathon-form", hackathon: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#hackathon-form", hackathon: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/hackathons")

      html = render(index_live)
      assert html =~ "Hackathon created successfully"
      assert html =~ "some name"
    end

    test "updates hackathon in listing", %{conn: conn, hackathon: hackathon} do
      {:ok, index_live, _html} = live(conn, ~p"/hackathons")

      assert index_live |> element("#hackathons-#{hackathon.id} a", "Edit") |> render_click() =~
               "Edit Hackathon"

      assert_patch(index_live, ~p"/hackathons/#{hackathon}/edit")

      assert index_live
             |> form("#hackathon-form", hackathon: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#hackathon-form", hackathon: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/hackathons")

      html = render(index_live)
      assert html =~ "Hackathon updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes hackathon in listing", %{conn: conn, hackathon: hackathon} do
      {:ok, index_live, _html} = live(conn, ~p"/hackathons")

      assert index_live |> element("#hackathons-#{hackathon.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#hackathons-#{hackathon.id}")
    end
  end

  describe "Show" do
    setup [:create_hackathon]

    test "displays hackathon", %{conn: conn, hackathon: hackathon} do
      {:ok, _show_live, html} = live(conn, ~p"/hackathons/#{hackathon}")

      assert html =~ "Show Hackathon"
      assert html =~ hackathon.name
    end

    test "updates hackathon within modal", %{conn: conn, hackathon: hackathon} do
      {:ok, show_live, _html} = live(conn, ~p"/hackathons/#{hackathon}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Hackathon"

      assert_patch(show_live, ~p"/hackathons/#{hackathon}/show/edit")

      assert show_live
             |> form("#hackathon-form", hackathon: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#hackathon-form", hackathon: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/hackathons/#{hackathon}")

      html = render(show_live)
      assert html =~ "Hackathon updated successfully"
      assert html =~ "some updated name"
    end
  end
end
