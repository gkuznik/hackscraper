defmodule HackScraper.EventsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HackScraper.Events` context.
  """

  @doc """
  Generate a series.
  """
  def series_fixture(attrs \\ %{}) do
    {:ok, series} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name"
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
        end_date: ~U[2025-11-09 15:56:00Z],
        image: "some image",
        location: "some location",
        name: "some name",
        start_date: ~U[2025-11-09 15:56:00Z],
        url: "some url"
      })
      |> HackScraper.Events.create_hackathon()

    hackathon
  end
end
