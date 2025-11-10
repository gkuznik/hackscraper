defmodule HackScraperWeb.HackathonControllerTest do
  use HackScraperWeb.ConnCase

  import HackScraper.EventsFixtures

  @create_attrs %{name: "some name", description: "some description", location: "some location", image: "some image", url: "some url", start_date: ~U[2025-11-09 15:56:00Z], end_date: ~U[2025-11-09 15:56:00Z]}
  @update_attrs %{name: "some updated name", description: "some updated description", location: "some updated location", image: "some updated image", url: "some updated url", start_date: ~U[2025-11-10 15:56:00Z], end_date: ~U[2025-11-10 15:56:00Z]}
  @invalid_attrs %{name: nil, description: nil, location: nil, image: nil, url: nil, start_date: nil, end_date: nil}

  describe "index" do
    test "lists all hackathons", %{conn: conn} do
      conn = get(conn, ~p"/hackathons")
      assert html_response(conn, 200) =~ "Listing Hackathons"
    end
  end

  describe "new hackathon" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/hackathons/new")
      assert html_response(conn, 200) =~ "New Hackathon"
    end
  end

  describe "create hackathon" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/hackathons", hackathon: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/hackathons/#{id}"

      conn = get(conn, ~p"/hackathons/#{id}")
      assert html_response(conn, 200) =~ "Hackathon #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/hackathons", hackathon: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Hackathon"
    end
  end

  describe "edit hackathon" do
    setup [:create_hackathon]

    test "renders form for editing chosen hackathon", %{conn: conn, hackathon: hackathon} do
      conn = get(conn, ~p"/hackathons/#{hackathon}/edit")
      assert html_response(conn, 200) =~ "Edit Hackathon"
    end
  end

  describe "update hackathon" do
    setup [:create_hackathon]

    test "redirects when data is valid", %{conn: conn, hackathon: hackathon} do
      conn = put(conn, ~p"/hackathons/#{hackathon}", hackathon: @update_attrs)
      assert redirected_to(conn) == ~p"/hackathons/#{hackathon}"

      conn = get(conn, ~p"/hackathons/#{hackathon}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, hackathon: hackathon} do
      conn = put(conn, ~p"/hackathons/#{hackathon}", hackathon: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Hackathon"
    end
  end

  describe "delete hackathon" do
    setup [:create_hackathon]

    test "deletes chosen hackathon", %{conn: conn, hackathon: hackathon} do
      conn = delete(conn, ~p"/hackathons/#{hackathon}")
      assert redirected_to(conn) == ~p"/hackathons"

      assert_error_sent 404, fn ->
        get(conn, ~p"/hackathons/#{hackathon}")
      end
    end
  end

  defp create_hackathon(_) do
    hackathon = hackathon_fixture()
    %{hackathon: hackathon}
  end
end
