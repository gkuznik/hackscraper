defmodule HackScraper.ScrapersTest do
  use HackScraper.DataCase

  alias HackScraper.Scrapers

  describe "scrapers" do
    alias HackScraper.Scrapers.Scraper

    import HackScraper.ScrapersFixtures

    @invalid_attrs %{worker: nil, url: nil, schedule: nil, paused: nil}

    test "list_scrapers/0 returns all scrapers" do
      scraper = scraper_fixture()
      assert Scrapers.list_scrapers() == [scraper]
    end

    test "get_scraper!/1 returns the scraper with given id" do
      scraper = scraper_fixture()
      assert Scrapers.get_scraper!(scraper.id) == scraper
    end

    test "create_scraper/1 with valid data creates a scraper" do
      valid_attrs = %{worker: "some worker", url: "some url", schedule: "some schedule", paused: true}

      assert {:ok, %Scraper{} = scraper} = Scrapers.create_scraper(valid_attrs)
      assert scraper.worker == "some worker"
      assert scraper.url == "some url"
      assert scraper.schedule == "some schedule"
      assert scraper.paused == true
    end

    test "create_scraper/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Scrapers.create_scraper(@invalid_attrs)
    end

    test "update_scraper/2 with valid data updates the scraper" do
      scraper = scraper_fixture()
      update_attrs = %{worker: "some updated worker", url: "some updated url", schedule: "some updated schedule", paused: false}

      assert {:ok, %Scraper{} = scraper} = Scrapers.update_scraper(scraper, update_attrs)
      assert scraper.worker == "some updated worker"
      assert scraper.url == "some updated url"
      assert scraper.schedule == "some updated schedule"
      assert scraper.paused == false
    end

    test "update_scraper/2 with invalid data returns error changeset" do
      scraper = scraper_fixture()
      assert {:error, %Ecto.Changeset{}} = Scrapers.update_scraper(scraper, @invalid_attrs)
      assert scraper == Scrapers.get_scraper!(scraper.id)
    end

    test "delete_scraper/1 deletes the scraper" do
      scraper = scraper_fixture()
      assert {:ok, %Scraper{}} = Scrapers.delete_scraper(scraper)
      assert_raise Ecto.NoResultsError, fn -> Scrapers.get_scraper!(scraper.id) end
    end

    test "change_scraper/1 returns a scraper changeset" do
      scraper = scraper_fixture()
      assert %Ecto.Changeset{} = Scrapers.change_scraper(scraper)
    end
  end
end
