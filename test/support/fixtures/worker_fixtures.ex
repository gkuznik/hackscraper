defmodule HackScraper.WorkerFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HackScraper.Worker` context.
  """

  @doc """
  Generate a scraper.
  """
  def scraper_fixture(attrs \\ %{}) do
    {:ok, scraper} =
      attrs
      |> Enum.into(%{
        name: "some name",
        paused: true,
        schedule: "some schedule",
        url: "some url"
      })
      |> HackScraper.Worker.create_scraper()

    scraper
  end
end
