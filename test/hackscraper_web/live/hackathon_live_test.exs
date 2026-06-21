defmodule HackScraperWeb.HackathonLiveTest do
  use HackScraperWeb.ConnCase

  import Phoenix.LiveViewTest
  import HackScraper.EventsFixtures
  import HackScraper.AccountsFixtures

  @create_attrs %{
    name: "some name",
    description: "some description",
    location: "some location",
    image: "some image",
    url: "some url",
    start_date: "2025-11-11T23:07:00Z",
    end_date: "2025-11-11T23:07:00Z"
  }
  @update_attrs %{
    name: "some updated name",
    description: "some updated description",
    location: "some updated location",
    image: "some updated image",
    url: "some updated url",
    start_date: "2025-11-12T23:07:00Z",
    end_date: "2025-11-12T23:07:00Z"
  }
  @invalid_attrs %{
    name: nil,
    description: nil,
    location: nil,
    image: nil,
    url: nil,
    start_date: nil,
    end_date: nil
  }

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
  end

  describe "Index_editor" do
    setup [:create_hackathon]

    test "saves new hackathon", %{conn: conn} do
      {:ok, index_live, _html} =
        log_in_user(conn, user_fixture(%{role: :editor})) |> live(~p"/hackathons")

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
      {:ok, index_live, _html} =
        log_in_user(conn, user_fixture(%{role: :editor})) |> live(~p"/hackathons")

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
      {:ok, index_live, _html} =
        log_in_user(conn, user_fixture(%{role: :editor})) |> live(~p"/hackathons")

      assert index_live |> element("#hackathons-#{hackathon.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#hackathons-#{hackathon.id}")
    end

    test "creating hackathon with duplicate url and date shows error", %{conn: conn} do
      existing = hackathon_fixture(%{url: "duplicate.com", start_date: ~U[2025-01-01 10:00:00Z]})

      {:ok, index_live, _html} =
        log_in_user(conn, user_fixture(%{role: :editor})) |> live(~p"/hackathons")

      assert index_live |> element("a", "New Hackathon") |> render_click()
      assert_patch(index_live, ~p"/hackathons/new")

      # Try to create hackathon with same url and start_date
      assert index_live
             |> form("#hackathon-form",
               hackathon: %{
                 name: "Another hackathon",
                 url: existing.url,
                 start_date: "2025-01-01T10:00",
                 end_date: "2025-01-01T12:00"
               }
             )
             |> render_submit() =~ "has already been taken"
    end

    test "updating hackathon with invalid data shows error", %{
      conn: conn,
      hackathon: hackathon
    } do
      {:ok, index_live, _html} =
        log_in_user(conn, user_fixture(%{role: :editor})) |> live(~p"/hackathons")

      assert index_live |> element("#hackathons-#{hackathon.id} a", "Edit") |> render_click()
      assert_patch(index_live, ~p"/hackathons/#{hackathon}/edit")

      # Submit with missing required fields
      html =
        index_live
        |> form("#hackathon-form", hackathon: %{name: "", url: ""})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "Index_without_privileges" do
    setup [:create_hackathon]

    test "saves new hackathon creates suggestion instead", %{conn: conn} do
      {:ok, new_live, _html} = log_in_user(conn, user_fixture()) |> live(~p"/hackathons/new")

      assert new_live
             |> form("#hackathon-form", hackathon: @update_attrs)
             |> render_submit()

      {path, flash} = assert_redirect(new_live)
      assert flash["info"] == "Suggestion submitted successfully"
      assert path =~ ~r/suggestions\/\d+/
      assert HackScraper.Events.list_suggestions() != []
    end

    test "deletes suggestion when editing hackathon with existing suggestion", %{
      conn: conn,
      hackathon: hackathon
    } do
      user = user_fixture()

      # Create a suggestion linked to this hackathon
      _suggestion =
        suggestion_fixture(%{
          creator_id: user.id,
          hackathon_id: hackathon.id,
          name: "Suggested edit"
        })

      {:ok, index_live, _html} = log_in_user(conn, user) |> live(~p"/hackathons")

      assert index_live |> element("#hackathons-#{hackathon.id} a", "Edit") |> render_click() =~
               "Edit Hackathon"

      assert_patch(index_live, ~p"/hackathons/#{hackathon}/edit")

      # Should show the suggestion hint
      html = render(index_live)
      assert html =~ "Existing Suggestion"
      assert html =~ "We&#39;ve loaded your existing suggestion"

      # Click delete suggestion button
      assert index_live
             |> element("button", "Delete Suggestion")
             |> render_click()

      # Suggestion should be deleted from database
      assert HackScraper.Events.list_suggestions() == []
    end
  end

  describe "Show" do
    setup [:create_hackathon]

    test "displays hackathon", %{conn: conn, hackathon: hackathon} do
      {:ok, _show_live, html} = live(conn, ~p"/hackathons/#{hackathon}")

      assert html =~ "Hackathon: "
      assert html =~ hackathon.name

      assert html =~ ~s(<meta property="og:title" content="#{hackathon.name}")
      assert html =~ ~s(<meta property="og:description" content="#{hackathon.description}")

      assert html =~
               ~s(<meta property="og:image" content="#{HackScraperWeb.Endpoint.url()}/#{hackathon.image}")

      assert html =~
               ~s(<meta property="og:url" content="#{HackScraperWeb.Endpoint.url()}/hackathons/#{hackathon.id}")

      assert html =~ ~s(<meta property="og:type" content="website")
      assert html =~ ~s(<meta name="twitter:title" content="#{hackathon.name}")
      assert html =~ ~s(<meta name="twitter:description" content="#{hackathon.description}")

      assert html =~
               ~s(<meta name="twitter:image" content="#{HackScraperWeb.Endpoint.url()}/#{hackathon.image}")

      assert html =~ ~s(<meta name="twitter:card" content="summary_large_image")
    end

    test "updates hackathon within modal", %{conn: conn, hackathon: hackathon} do
      {:ok, show_live, _html} =
        log_in_user(conn, user_fixture(%{role: :editor})) |> live(~p"/hackathons/#{hackathon}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit"

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

    test "deletes suggestion when editing hackathon from show page", %{
      conn: conn,
      hackathon: hackathon
    } do
      user = user_fixture()

      # Create a suggestion linked to this hackathon
      suggestion_fixture(%{
        creator_id: user.id,
        hackathon_id: hackathon.id,
        name: "Suggested edit"
      })

      {:ok, show_live, _html} = log_in_user(conn, user) |> live(~p"/hackathons/#{hackathon}")

      assert show_live |> element("a", "Edit") |> render_click() =~ "Edit"

      assert_patch(show_live, ~p"/hackathons/#{hackathon}/show/edit")

      # Should show the suggestion hint
      html = render(show_live)
      assert html =~ "Existing Suggestion"
      assert html =~ "We&#39;ve loaded your existing suggestion"

      assert show_live
             |> element("button", "Delete Suggestion")
             |> render_click()

      assert HackScraper.Events.list_suggestions() == []
    end

    test "updating hackathon with invalid data shows error", %{
      conn: conn,
      hackathon: hackathon
    } do
      {:ok, show_live, _html} =
        log_in_user(conn, user_fixture(%{role: :editor})) |> live(~p"/hackathons/#{hackathon}")

      assert show_live |> element("a", "Edit") |> render_click()
      assert_patch(show_live, ~p"/hackathons/#{hackathon}/show/edit")

      # Submit with missing required fields
      html =
        show_live
        |> form("#hackathon-form", hackathon: %{name: "", url: ""})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "Scraper Autocomplete" do
    test "automatically scrapes URL and offers autofill", %{conn: conn} do
      # Mock HTML response for the URL
      mock_html = """
      <html>
        <head>
          <title>Super Hackathon 2026 - The Tech Event</title>
          <meta name="description" content="A coding marathon for developers.">
          <meta property="og:image" content="https://example.com/logo.png">
        </head>
        <body>
          <p>Join us on 2026-07-20!</p>
        </body>
      </html>
      """

      Req.Test.stub(HackScraper, fn conn ->
        Req.Test.html(conn, mock_html)
      end)

      {:ok, new_live, _html} =
        log_in_user(conn, user_fixture(%{role: :editor})) |> live(~p"/hackathons/new")

      # Fill in URL and trigger validation
      assert new_live
             |> form("#hackathon-form", hackathon: %{url: "https://example.com/super-hack"})
             |> render_change()

      # Wait for scraping to complete (up to 5 seconds)
      html =
        eventually(fn ->
          html = render(new_live)

          if html =~ "Scraping URL information..." do
            Process.sleep(100)
            :retry
          else
            html
          end
        end)

      assert html =~ "We found details for this hackathon"
      assert html =~ "Super Hackathon 2026"
      assert html =~ "A coding marathon for developers."
      assert html =~ "https://example.com/logo.png"

      # Click the Autofill button
      assert new_live
             |> element("button", "Autofill")
             |> render_click()

      # Now check if the form inputs are updated with the scraped values
      assert new_live |> element("input[name=\"hackathon[name]\"]") |> render() =~
               "value=\"Super Hackathon 2026\""

      assert new_live |> element("textarea[name=\"hackathon[description]\"]") |> render() =~
               "A coding marathon for developers."

      assert new_live |> element("input[name=\"hackathon[image]\"]") |> render() =~
               "value=\"https://example.com/logo.png\""

      # The date hint box should also be visible
      assert render(new_live) =~ "Date information found:"
      assert render(new_live) =~ "2026-07-20"
    end
  end

  defp eventually(fun, attempts \\ 50) do
    case fun.() do
      :retry when attempts > 0 ->
        eventually(fun, attempts - 1)

      res ->
        res
    end
  end
end
