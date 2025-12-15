defmodule HackScraperWeb.SuggestionLiveTest do
  use HackScraperWeb.ConnCase

  import Phoenix.LiveViewTest
  import HackScraper.EventsFixtures
  import HackScraper.AccountsFixtures

  defp create_suggestion(_) do
    suggestion = suggestion_fixture()
    %{suggestion: suggestion}
  end

  describe "Index_user" do
    test "lists only own suggestions", %{conn: conn} do
      user = user_fixture()

      my_suggestion =
        suggestion_fixture(%{creator_id: user.id, name: "my suggestion", url: "my url"})

      other_suggestion = suggestion_fixture()

      {:ok, _index_live, html} =
        log_in_user(conn, user) |> live(~p"/suggestions")

      assert html =~ "Listing Suggestions"
      assert html =~ my_suggestion.name
      refute html =~ other_suggestion.name
    end

    test "reviewing own suggestion and updating one field updates suggestion without creating hackathon",
         %{conn: conn} do
      user = user_fixture()

      suggestion =
        suggestion_fixture(%{
          creator_id: user.id,
          name: "Original Name",
          url: "original.com",
          start_date: ~U[2025-01-01 10:00:00Z]
        })

      {:ok, index_live, _html} =
        log_in_user(conn, user) |> live(~p"/suggestions")

      assert index_live |> element("#suggestions-#{suggestion.id} a", "Review") |> render_click() =~
               "Review Suggestion"

      assert_patch(index_live, ~p"/suggestions/#{suggestion}/review")

      assert index_live
             |> form("#hackathon-form", hackathon: %{name: "Updated Name"})
             |> render_submit()

      {path, flash} = assert_redirect(index_live)
      assert flash["info"] == "Suggestion submitted successfully"
      assert path == ~p"/suggestions/#{suggestion}"

      # suggestion was updated, not deleted
      updated_suggestion = HackScraper.Events.get_suggestion!(suggestion.id)
      assert updated_suggestion.name == "Updated Name"
      assert updated_suggestion.url == suggestion.url

      # no hackathon was created
      assert HackScraper.Repo.aggregate(HackScraper.Events.Hackathon, :count) == 0
    end

    test "deletes own suggestion in listing", %{conn: conn} do
      user = user_fixture()
      my_suggestion = suggestion_fixture(%{creator_id: user.id})

      {:ok, index_live, _html} =
        log_in_user(conn, user) |> live(~p"/suggestions")

      assert index_live
             |> element("#suggestions-#{my_suggestion.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#suggestions-#{my_suggestion.id}")
    end
  end

  describe "Index_editor" do
    setup [:create_suggestion]

    test "lists all suggestions", %{conn: conn, suggestion: suggestion} do
      {:ok, _index_live, html} =
        log_in_user(conn, user_fixture(%{role: :editor})) |> live(~p"/suggestions")

      assert html =~ "Listing Suggestions"
      assert html =~ suggestion.name
    end

    test "review suggestion in listing and create hackathon", %{
      conn: conn,
      suggestion: suggestion
    } do
      {:ok, index_live, _html} =
        log_in_user(conn, user_fixture(%{role: :editor})) |> live(~p"/suggestions")

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
      {:ok, index_live, _html} =
        log_in_user(conn, user_fixture(%{role: :editor})) |> live(~p"/suggestions")

      assert index_live |> element("#suggestions-#{suggestion.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#suggestions-#{suggestion.id}")
    end
  end

  describe "Show_user" do
    test "displays own suggestion", %{conn: conn} do
      user = user_fixture()
      suggestion = suggestion_fixture(%{creator_id: user.id})

      {:ok, _show_live, html} =
        log_in_user(conn, user) |> live(~p"/suggestions/#{suggestion}")

      assert html =~ "Suggestion: "
      assert html =~ suggestion.name
    end

    test "reviewing own suggestion and updating one field updates suggestion without creating hackathon",
         %{conn: conn} do
      user = user_fixture()

      suggestion =
        suggestion_fixture(%{
          creator_id: user.id,
          name: "Original Name",
          url: "original.com",
          start_date: ~U[2025-01-01 10:00:00Z]
        })

      {:ok, show_live, _html} =
        log_in_user(conn, user) |> live(~p"/suggestions/#{suggestion}")

      assert show_live |> element("a", "Review") |> render_click() =~
               "Review "

      assert_patch(show_live, ~p"/suggestions/#{suggestion}/show/review")

      assert show_live
             |> form("#hackathon-form", hackathon: %{name: "Updated Name"})
             |> render_submit()

      {path, flash} = assert_redirect(show_live)
      assert flash["info"] == "Suggestion submitted successfully"
      assert path == ~p"/suggestions/#{suggestion}"

      # suggestion was updated, not deleted
      updated_suggestion = HackScraper.Events.get_suggestion!(suggestion.id)
      assert updated_suggestion.name == "Updated Name"
      assert updated_suggestion.url == suggestion.url

      # no hackathon was created
      assert HackScraper.Repo.aggregate(HackScraper.Events.Hackathon, :count) == 0
    end
  end

  describe "Show_editor" do
    setup [:create_suggestion]

    test "displays suggestion", %{conn: conn, suggestion: suggestion} do
      {:ok, _show_live, html} =
        log_in_user(conn, user_fixture(%{role: :editor})) |> live(~p"/suggestions/#{suggestion}")

      assert html =~ "Suggestion: "
      assert html =~ suggestion.name
    end

    test "review suggestion within modal and create hackathon", %{
      conn: conn,
      suggestion: suggestion
    } do
      {:ok, show_live, _html} =
        log_in_user(conn, user_fixture(%{role: :editor})) |> live(~p"/suggestions/#{suggestion}")

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
