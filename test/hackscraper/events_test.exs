defmodule HackScraper.EventsTest do
  use HackScraper.DataCase

  alias HackScraper.Events

  describe "series" do
    alias HackScraper.Events.Series

    import HackScraper.EventsFixtures

    @invalid_attrs %{name: nil, description: nil, image: nil, url: nil}

    test "list_series/0 returns all series" do
      series = series_fixture()
      assert Events.list_series() == [series]
    end

    test "get_series!/1 returns the series with given id" do
      series = series_fixture()
      assert Events.get_series!(series.id) == series
    end

    test "create_series/1 with valid data creates a series" do
      valid_attrs = %{name: "some name", description: "some description", image: "some image", url: "some url"}

      assert {:ok, %Series{} = series} = Events.create_series(valid_attrs)
      assert series.name == "some name"
      assert series.description == "some description"
      assert series.image == "some image"
      assert series.url == "some url"
    end

    test "create_series/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_series(@invalid_attrs)
    end

    test "update_series/2 with valid data updates the series" do
      series = series_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description", image: "some updated image", url: "some updated url"}

      assert {:ok, %Series{} = series} = Events.update_series(series, update_attrs)
      assert series.name == "some updated name"
      assert series.description == "some updated description"
      assert series.image == "some updated image"
      assert series.url == "some updated url"
    end

    test "update_series/2 with invalid data returns error changeset" do
      series = series_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_series(series, @invalid_attrs)
      assert series == Events.get_series!(series.id)
    end

    test "delete_series/1 deletes the series" do
      series = series_fixture()
      assert {:ok, %Series{}} = Events.delete_series(series)
      assert_raise Ecto.NoResultsError, fn -> Events.get_series!(series.id) end
    end

    test "change_series/1 returns a series changeset" do
      series = series_fixture()
      assert %Ecto.Changeset{} = Events.change_series(series)
    end
  end

  describe "hackathons" do
    alias HackScraper.Events.Hackathon

    import HackScraper.EventsFixtures

    @invalid_attrs %{name: nil, description: nil, location: nil, image: nil, url: nil, start_date: nil, end_date: nil}

    test "list_hackathons/0 returns all hackathons" do
      hackathon = hackathon_fixture()
      assert Events.list_hackathons() == [hackathon]
    end

    test "get_hackathon!/1 returns the hackathon with given id" do
      hackathon = hackathon_fixture()
      assert Events.get_hackathon!(hackathon.id) == hackathon
    end

    test "create_hackathon/1 with valid data creates a hackathon" do
      valid_attrs = %{name: "some name", description: "some description", location: "some location", image: "some image", url: "some url", start_date: ~U[2025-11-11 22:55:00Z], end_date: ~U[2025-11-11 22:55:00Z]}

      assert {:ok, %Hackathon{} = hackathon} = Events.create_hackathon(valid_attrs)
      assert hackathon.name == "some name"
      assert hackathon.description == "some description"
      assert hackathon.location == "some location"
      assert hackathon.image == "some image"
      assert hackathon.url == "some url"
      assert hackathon.start_date == ~U[2025-11-11 22:55:00Z]
      assert hackathon.end_date == ~U[2025-11-11 22:55:00Z]
    end

    test "create_hackathon/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_hackathon(@invalid_attrs)
    end

    test "update_hackathon/2 with valid data updates the hackathon" do
      hackathon = hackathon_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description", location: "some updated location", image: "some updated image", url: "some updated url", start_date: ~U[2025-11-12 22:55:00Z], end_date: ~U[2025-11-12 22:55:00Z]}

      assert {:ok, %Hackathon{} = hackathon} = Events.update_hackathon(hackathon, update_attrs)
      assert hackathon.name == "some updated name"
      assert hackathon.description == "some updated description"
      assert hackathon.location == "some updated location"
      assert hackathon.image == "some updated image"
      assert hackathon.url == "some updated url"
      assert hackathon.start_date == ~U[2025-11-12 22:55:00Z]
      assert hackathon.end_date == ~U[2025-11-12 22:55:00Z]
    end

    test "update_hackathon/2 with invalid data returns error changeset" do
      hackathon = hackathon_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_hackathon(hackathon, @invalid_attrs)
      assert hackathon == Events.get_hackathon!(hackathon.id)
    end

    test "delete_hackathon/1 deletes the hackathon" do
      hackathon = hackathon_fixture()
      assert {:ok, %Hackathon{}} = Events.delete_hackathon(hackathon)
      assert_raise Ecto.NoResultsError, fn -> Events.get_hackathon!(hackathon.id) end
    end

    test "change_hackathon/1 returns a hackathon changeset" do
      hackathon = hackathon_fixture()
      assert %Ecto.Changeset{} = Events.change_hackathon(hackathon)
    end
  end

  describe "suggestions" do
    alias HackScraper.Events.Suggestion

    import HackScraper.EventsFixtures

    @invalid_attrs %{name: nil, date: nil, description: nil, location: nil, image: nil, url: nil, start_date: nil, end_date: nil}

    test "list_suggestions/0 returns all suggestions" do
      suggestion = suggestion_fixture()
      assert Events.list_suggestions() == [suggestion]
    end

    test "get_suggestion!/1 returns the suggestion with given id" do
      suggestion = suggestion_fixture()
      assert Events.get_suggestion!(suggestion.id) == suggestion
    end

    test "create_suggestion/1 with valid data creates a suggestion" do
      valid_attrs = %{name: "some name", date: "some date", description: "some description", location: "some location", image: "some image", url: "some url", start_date: ~U[2025-11-16 16:50:00Z], end_date: ~U[2025-11-16 16:50:00Z]}

      assert {:ok, %Suggestion{} = suggestion} = Events.create_suggestion(valid_attrs)
      assert suggestion.name == "some name"
      assert suggestion.date == "some date"
      assert suggestion.description == "some description"
      assert suggestion.location == "some location"
      assert suggestion.image == "some image"
      assert suggestion.url == "some url"
      assert suggestion.start_date == ~U[2025-11-16 16:50:00Z]
      assert suggestion.end_date == ~U[2025-11-16 16:50:00Z]
    end

    test "create_suggestion/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_suggestion(@invalid_attrs)
    end

    test "update_suggestion/2 with valid data updates the suggestion" do
      suggestion = suggestion_fixture()
      update_attrs = %{name: "some updated name", date: "some updated date", description: "some updated description", location: "some updated location", image: "some updated image", url: "some updated url", start_date: ~U[2025-11-17 16:50:00Z], end_date: ~U[2025-11-17 16:50:00Z]}

      assert {:ok, %Suggestion{} = suggestion} = Events.update_suggestion(suggestion, update_attrs)
      assert suggestion.name == "some updated name"
      assert suggestion.date == "some updated date"
      assert suggestion.description == "some updated description"
      assert suggestion.location == "some updated location"
      assert suggestion.image == "some updated image"
      assert suggestion.url == "some updated url"
      assert suggestion.start_date == ~U[2025-11-17 16:50:00Z]
      assert suggestion.end_date == ~U[2025-11-17 16:50:00Z]
    end

    test "update_suggestion/2 with invalid data returns error changeset" do
      suggestion = suggestion_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_suggestion(suggestion, @invalid_attrs)
      assert suggestion == Events.get_suggestion!(suggestion.id)
    end

    test "delete_suggestion/1 deletes the suggestion" do
      suggestion = suggestion_fixture()
      assert {:ok, %Suggestion{}} = Events.delete_suggestion(suggestion)
      assert_raise Ecto.NoResultsError, fn -> Events.get_suggestion!(suggestion.id) end
    end

    test "change_suggestion/1 returns a suggestion changeset" do
      suggestion = suggestion_fixture()
      assert %Ecto.Changeset{} = Events.change_suggestion(suggestion)
    end
  end
end
