defmodule HackScraperWeb.SuggestionLiveTest do
  use HackScraperWeb.ConnCase

  import Phoenix.LiveViewTest
  import HackScraper.EventsFixtures

  @create_attrs %{name: "some name", date: "some date", description: "some description", location: "some location", image: "some image", url: "some url", start_date: "2025-11-16T16:50:00Z", end_date: "2025-11-16T16:50:00Z"}
  @update_attrs %{name: "some updated name", date: "some updated date", description: "some updated description", location: "some updated location", image: "some updated image", url: "some updated url", start_date: "2025-11-17T16:50:00Z", end_date: "2025-11-17T16:50:00Z"}
  @invalid_attrs %{name: nil, date: nil, description: nil, location: nil, image: nil, url: nil, start_date: nil, end_date: nil}

  defp create_suggestion(_) do
    suggestion = suggestion_fixture()
    %{suggestion: suggestion}
  end

  describe "Index" do
    setup [:create_suggestion]

    test "lists all suggestions", %{conn: conn, suggestion: suggestion} do
      {:ok, _index_live, html} = live(conn, ~p"/suggestions")

      assert html =~ "Listing Suggestions"
      assert html =~ suggestion.name
    end


    test "review suggestion in listing", %{conn: conn, suggestion: suggestion} do
      {:ok, index_live, _html} = live(conn, ~p"/suggestions")

      assert index_live |> element("#suggestions-#{suggestion.id} a", "Review") |> render_click() =~
               "Review Suggestion"

      assert_patch(index_live, ~p"/suggestions/#{suggestion}/review")

      assert index_live
             |> form("#hackathon-form", suggestion: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#hackathon-form", suggestion: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/hackathons")

      html = render(index_live)
      assert html =~ "Hackathon created successfully"
      assert html =~ "some updated name"
    end

    test "deletes suggestion in listing", %{conn: conn, suggestion: suggestion} do
      {:ok, index_live, _html} = live(conn, ~p"/suggestions")

      assert index_live |> element("#suggestions-#{suggestion.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#suggestions-#{suggestion.id}")
    end
  end

  describe "Show" do
    setup [:create_suggestion]

    test "displays suggestion", %{conn: conn, suggestion: suggestion} do
      {:ok, _show_live, html} = live(conn, ~p"/suggestions/#{suggestion}")

      assert html =~ "Show Suggestion"
      assert html =~ suggestion.name
    end

    test "updates suggestion within modal", %{conn: conn, suggestion: suggestion} do
      {:ok, show_live, _html} = live(conn, ~p"/suggestions/#{suggestion}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Suggestion"

      assert_patch(show_live, ~p"/suggestions/#{suggestion}/show/edit")

      assert show_live
             |> form("#suggestion-form", suggestion: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#suggestion-form", suggestion: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/suggestions/#{suggestion}")

      html = render(show_live)
      assert html =~ "Suggestion updated successfully"
      assert html =~ "some updated name"
    end
  end
end
