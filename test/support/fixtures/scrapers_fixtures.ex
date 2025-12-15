defmodule HackScraper.ScrapersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HackScraper.Scrapers` context.
  """

  @doc """
  Generate a scraper.
  """
  def scraper_fixture(attrs \\ %{}) do
    {:ok, scraper} =
      attrs
      |> Enum.into(%{
        worker: "Dummy",
        paused: true,
        schedule: "@weekly",
        url: "some url"
      })
      |> HackScraper.Scrapers.create_scraper()

    scraper
  end
end
