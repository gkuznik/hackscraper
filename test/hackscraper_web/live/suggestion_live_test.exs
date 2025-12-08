defmodule HackScraperWeb.SuggestionLiveTest do
  use HackScraperWeb.ConnCase

  import Phoenix.LiveViewTest
  import HackScraper.EventsFixtures
  import HackScraper.AccountsFixtures

  defp create_suggestion(_) do
    suggestion = suggestion_fixture()
    %{suggestion: suggestion}
  end

  describe "Index" do
    setup [:create_suggestion]

    test "lists all suggestions", %{conn: conn, suggestion: suggestion} do
      {:ok, _index_live, html} = log_in_user(conn, user_fixture()) |> live(~p"/suggestions")

      assert html =~ "Listing Suggestions"
      assert html =~ suggestion.name
    end

    test "review suggestion in listing and create hackathon", %{
      conn: conn,
      suggestion: suggestion
    } do
      {:ok, index_live, _html} = log_in_user(conn, user_fixture()) |> live(~p"/suggestions")

      assert index_live |> element("#suggestions-#{suggestion.id} a", "Review") |> render_click() =~
               "Review Suggestion"

      assert_patch(index_live, ~p"/suggestions/#{suggestion}/review")

      assert index_live
             |> form("#hackathon-form")
             |> render_submit()

      assert_patch(index_live, ~p"/suggestions")

      html = render(index_live)
      assert html =~ "Hackathon created successfully"

      refute has_element?(index_live, "#suggestions-#{suggestion.id}")
    end

    test "deletes suggestion in listing", %{conn: conn, suggestion: suggestion} do
      {:ok, index_live, _html} = log_in_user(conn, user_fixture()) |> live(~p"/suggestions")

      assert index_live |> element("#suggestions-#{suggestion.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#suggestions-#{suggestion.id}")
    end
  end

  describe "Show" do
    setup [:create_suggestion]

    test "displays suggestion", %{conn: conn, suggestion: suggestion} do
      {:ok, _show_live, html} =
        log_in_user(conn, user_fixture()) |> live(~p"/suggestions/#{suggestion}")

      assert html =~ "Suggestion: "
      assert html =~ suggestion.name
    end

    test "review suggestion within modal and create hackathon", %{
      conn: conn,
      suggestion: suggestion
    } do
      {:ok, show_live, _html} =
        log_in_user(conn, user_fixture()) |> live(~p"/suggestions/#{suggestion}")

      assert show_live |> element("a", "Review") |> render_click() =~
               "Review some name"

      assert_patch(show_live, ~p"/suggestions/#{suggestion}/show/review")

      assert show_live
             |> form("#hackathon-form")
             |> render_submit()

      {path, flash} = assert_redirect(show_live)
      assert flash["info"] == "Suggestion published as Hackathon"
      assert path =~ ~r/hackathons\/\d+/

      {:ok, show_live, _html} = log_in_user(conn, user_fixture()) |> live(~p"/suggestions/")
      refute has_element?(show_live, "#suggestions-#{suggestion.id}")
    end
  end
end
