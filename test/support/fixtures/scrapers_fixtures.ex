defmodule HackScraper.ScrapersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HackScraper.Scrapers` context.
  """

  def unique_scraper_name, do: "scraper#{System.unique_integer()}"
  def unique_scraper_url, do: "http://example.com/scraper#{System.unique_integer()}"

  @doc """
  Generate a scraper.
  """
  def scraper_fixture(attrs \\ %{}) do
    {:ok, scraper} =
      attrs
      |> Enum.into(%{
        name: unique_scraper_name(),
        worker: "Dummy",
        paused: true,
        schedule: "@weekly",
        url: unique_scraper_url()
      })
      |> HackScraper.Scrapers.create_scraper()

    scraper
  end
end
