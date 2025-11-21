defmodule HackScraper.WorkerTest do
  use HackScraper.DataCase

  alias HackScraper.Worker

  describe "scrapers" do
    alias HackScraper.Worker.Scraper

    import HackScraper.WorkerFixtures

    @invalid_attrs %{name: nil, url: nil, schedule: nil, paused: nil}

    test "list_scrapers/0 returns all scrapers" do
      scraper = scraper_fixture()
      assert Worker.list_scrapers() == [scraper]
    end

    test "get_scraper!/1 returns the scraper with given id" do
      scraper = scraper_fixture()
      assert Worker.get_scraper!(scraper.id) == scraper
    end

    test "create_scraper/1 with valid data creates a scraper" do
      valid_attrs = %{name: "some name", url: "some url", schedule: "some schedule", paused: true}

      assert {:ok, %Scraper{} = scraper} = Worker.create_scraper(valid_attrs)
      assert scraper.name == "some name"
      assert scraper.url == "some url"
      assert scraper.schedule == "some schedule"
      assert scraper.paused == true
    end

    test "create_scraper/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Worker.create_scraper(@invalid_attrs)
    end

    test "update_scraper/2 with valid data updates the scraper" do
      scraper = scraper_fixture()
      update_attrs = %{name: "some updated name", url: "some updated url", schedule: "some updated schedule", paused: false}

      assert {:ok, %Scraper{} = scraper} = Worker.update_scraper(scraper, update_attrs)
      assert scraper.name == "some updated name"
      assert scraper.url == "some updated url"
      assert scraper.schedule == "some updated schedule"
      assert scraper.paused == false
    end

    test "update_scraper/2 with invalid data returns error changeset" do
      scraper = scraper_fixture()
      assert {:error, %Ecto.Changeset{}} = Worker.update_scraper(scraper, @invalid_attrs)
      assert scraper == Worker.get_scraper!(scraper.id)
    end

    test "delete_scraper/1 deletes the scraper" do
      scraper = scraper_fixture()
      assert {:ok, %Scraper{}} = Worker.delete_scraper(scraper)
      assert_raise Ecto.NoResultsError, fn -> Worker.get_scraper!(scraper.id) end
    end

    test "change_scraper/1 returns a scraper changeset" do
      scraper = scraper_fixture()
      assert %Ecto.Changeset{} = Worker.change_scraper(scraper)
    end
  end
end
