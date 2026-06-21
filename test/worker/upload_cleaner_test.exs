defmodule HackScraper.Worker.UploadCleanerTest do
  use HackScraper.DataCase, async: false

  alias HackScraper.Worker.UploadCleaner
  import HackScraper.EventsFixtures

  setup do
    # Create a unique temporary directory for this test run to isolate from the actual upload storage.
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "hackscraper_test_uploads_#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp_dir)

    old_uploads_dir = Application.get_env(:hackscraper, :uploads_dir)
    Application.put_env(:hackscraper, :uploads_dir, tmp_dir)

    on_exit(fn ->
      Application.put_env(:hackscraper, :uploads_dir, old_uploads_dir)
      File.rm_rf!(tmp_dir)
    end)

    {:ok, tmp_dir: tmp_dir}
  end

  describe "perform/1" do
    test "cleans unreferenced files and keeps referenced files", %{tmp_dir: tmp_dir} do
      File.write!(Path.join(tmp_dir, "referenced_hackathon.jpg"), "hackathon image content")
      File.write!(Path.join(tmp_dir, "referenced_series.jpg"), "series image content")
      File.write!(Path.join(tmp_dir, "referenced_suggestion.jpg"), "suggestion image content")
      File.write!(Path.join(tmp_dir, "unreferenced.jpg"), "unreferenced image content")
      # Special file to skip
      File.write!(Path.join(tmp_dir, ".gitkeep"), "")

      # Create sub-directory to ensure it is skipped and not crashed on
      sub_dir = Path.join(tmp_dir, "some_sub_dir")
      File.mkdir_p!(sub_dir)

      # Create database records
      hackathon_fixture(%{image: "/uploads/referenced_hackathon.jpg"})
      series_fixture(%{image: "/uploads/referenced_series.jpg"})
      suggestion_fixture(%{image: "/uploads/referenced_suggestion.jpg"})

      # Verify files exist before running the worker
      assert File.exists?(Path.join(tmp_dir, "referenced_hackathon.jpg"))
      assert File.exists?(Path.join(tmp_dir, "referenced_series.jpg"))
      assert File.exists?(Path.join(tmp_dir, "referenced_suggestion.jpg"))
      assert File.exists?(Path.join(tmp_dir, "unreferenced.jpg"))
      assert File.exists?(Path.join(tmp_dir, ".gitkeep"))
      assert File.dir?(sub_dir)

      assert :ok = UploadCleaner.perform(%Oban.Job{})

      # Verify only the unreferenced file has been deleted
      assert File.exists?(Path.join(tmp_dir, "referenced_hackathon.jpg"))
      assert File.exists?(Path.join(tmp_dir, "referenced_series.jpg"))
      assert File.exists?(Path.join(tmp_dir, "referenced_suggestion.jpg"))
      refute File.exists?(Path.join(tmp_dir, "unreferenced.jpg"))
      assert File.exists?(Path.join(tmp_dir, ".gitkeep"))
      assert File.dir?(sub_dir)
    end

    test "handles URLs properly", %{tmp_dir: tmp_dir} do
      File.write!(Path.join(tmp_dir, "relative.jpg"), "relative")
      File.write!(Path.join(tmp_dir, "absolute.jpg"), "absolute")
      File.write!(Path.join(tmp_dir, "unreferenced.jpg"), "unreferenced")

      # Create database records
      series_fixture(%{image: "/uploads/relative.jpg"})

      series_fixture(%{
        image: "http://" <> HackScraperWeb.Endpoint.host() <> "/uploads/absolute.jpg"
      })

      series_fixture(%{image: "https://example.com/unreferenced.jpg"})
      series_fixture(%{image: "https://example.com/uploads/unreferenced.jpg"})

      assert :ok = UploadCleaner.perform(%Oban.Job{})

      assert File.exists?(Path.join(tmp_dir, "relative.jpg"))
      assert File.exists?(Path.join(tmp_dir, "absolute.jpg"))
      refute File.exists?(Path.join(tmp_dir, "unreferenced.jpg"))
    end
  end
end
