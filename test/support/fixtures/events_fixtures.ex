defmodule HackScraper.EventsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HackScraper.Events` context.
  """

  def unique_series_name, do: "series#{System.unique_integer()}"

  @doc """
  Generate a series.
  """
  def series_fixture(attrs \\ %{}) do
    {:ok, series} =
      attrs
      |> Enum.into(%{
        description: "some description",
        image: "some image",
        name: unique_series_name(),
        url: "some url"
      })
      |> HackScraper.Events.create_series()

    series
  end

  @doc """
  Generate a hackathon.
  """
  def hackathon_fixture(attrs \\ %{}) do
    {:ok, hackathon} =
      attrs
      |> Enum.into(%{
        description: "some description",
        end_date: ~U[2025-11-11 22:55:00Z],
        image: "some image",
        location: "some location",
        name: "some name",
        start_date: ~U[2025-11-11 22:55:00Z],
        url: "some url"
      })
      |> HackScraper.Events.create_hackathon()

    # preload the series
    Map.put(hackathon, :series, nil)
  end

  @doc """
  Generate a suggestion.
  """
  def suggestion_fixture(attrs \\ %{}) do
    {:ok, suggestion} =
      attrs
      |> Enum.into(%{
        date: "some date",
        description: "some description",
        end_date: ~U[2025-11-16 16:50:00Z],
        image: "some image",
        location: "some location",
        name: "some name",
        start_date: ~U[2025-11-16 16:50:00Z],
        url: "some url"
      })
      |> HackScraper.Events.create_suggestion()

    suggestion
  end
end
