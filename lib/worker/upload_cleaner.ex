defmodule HackScraper.Worker.UploadCleaner do
  use Oban.Worker, queue: :default, max_attempts: 2

  import Ecto.Query
  require Logger

  alias HackScraper.Repo
  alias HackScraper.Events.Hackathon
  alias HackScraper.Events.Series
  alias HackScraper.Events.Suggestion

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    uploads_dir = Application.fetch_env!(:hackscraper, :uploads_dir)
    Logger.info("Starting uploads cleanup job in directory: #{uploads_dir}")

    case File.ls(uploads_dir) do
      {:ok, files} ->
        referenced_files = get_referenced_files()

        Enum.each(files, fn file ->
          full_path = Path.join(uploads_dir, file)

          # Skip directories and special files like .gitkeep / .gitignore
          if not File.dir?(full_path) and file not in [".gitkeep", ".gitignore"] do
            unless MapSet.member?(referenced_files, file) do
              Logger.info("Deleting unreferenced upload file: #{file}")

              case File.rm(full_path) do
                :ok -> :ok
                {:error, reason} -> Logger.error("Failed to delete #{file}: #{inspect(reason)}")
              end
            end
          end
        end)

        :ok

      {:error, reason} ->
        Logger.error("Failed to list uploads directory: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp get_referenced_files do
    local_host = HackScraperWeb.Endpoint.host()
    host_pattern = "%#{local_host}/uploads/%"

    hackathon_images =
      Repo.all(
        from h in Hackathon,
          where:
            not is_nil(h.image) and (like(h.image, "/uploads/%") or like(h.image, ^host_pattern)),
          select: h.image
      )

    series_images =
      Repo.all(
        from s in Series,
          where:
            not is_nil(s.image) and (like(s.image, "/uploads/%") or like(s.image, ^host_pattern)),
          select: s.image
      )

    suggestion_images =
      Repo.all(
        from su in Suggestion,
          where:
            not is_nil(su.image) and
              (like(su.image, "/uploads/%") or like(su.image, ^host_pattern)),
          select: su.image
      )

    [hackathon_images, series_images, suggestion_images]
    |> Enum.concat()
    |> Enum.map(&extract_filename(&1, local_host))
    |> Enum.filter(&(not is_nil(&1)))
    |> MapSet.new()
  end

  defp extract_filename(image, local_host) do
    case URI.parse(image) do
      %URI{scheme: nil, host: nil, path: "/uploads/" <> filename} ->
        filename

      %URI{scheme: scheme, host: host, path: "/uploads/" <> filename}
      when scheme in ["http", "https"] and host == local_host ->
        filename

      _ ->
        nil
    end
  end
end
