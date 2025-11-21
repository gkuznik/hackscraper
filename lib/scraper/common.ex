defmodule HackScraper.Scraper.Common do
  alias HackScraper.Events.Suggestion
  alias HackScraper.Events.Hackathon

  @oban_opts [queue: :scraper, max_attempts: 1]
  @user_agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko; HackScraper/#{Application.spec(:mensaplan, :vsn)}; hack.gabriels.cloud) Chrome/134.0.0.0 Safari/537.3"

  def oban_opts, do: @oban_opts

  def get!(api_url) do
    Req.get!(api_url, http_errors: :raise, user_agent: @user_agent)
  end

  def upsert_suggestions([]), do: 0

  def upsert_suggestions(suggestions) do
    # Filter out suggestions where both URL and name already exist in hackathons
    filtered_suggestions = filter_existing_hackathons(suggestions)

    timestamp = DateTime.utc_now(:second)

    placeholders = %{timestamp: timestamp}

    maps =
      Enum.map(
        filtered_suggestions,
        fn s -> Map.put(s, :inserted_at, {:placeholder, :timestamp}) end
      )

    {num, _} =
      HackScraper.Repo.insert_all(
        Suggestion,
        maps,
        placeholders: placeholders,
        on_conflict: {:replace_all_except, [:id, :url]},
        conflict_target: [:url]
      )

    num
  end

  defp filter_existing_hackathons(suggestions) do
    import Ecto.Query

    existing_hackathons =
      HackScraper.Repo.all(
        from h in Hackathon,
        select: %{url: h.url, name: h.name}
      )

    existing_set =
      existing_hackathons
      |> Enum.map(fn h -> {h.url, h.name} end)
      |> MapSet.new()

    Enum.reject(suggestions, fn suggestion ->
      MapSet.member?(existing_set, {suggestion[:url], suggestion[:name]})
    end)
  end

  def upsert_hackathons([]), do: 0

  def upsert_hackathons(hackathons) do
    timestamp = DateTime.utc_now(:second)

    placeholders = %{timestamp: timestamp}

    maps =
      Enum.map(
        hackathons,
        &%{
          hackathon: &1,
          inserted_at: {:placeholder, :timestamp},
          updated_at: {:placeholder, :timestamp}
        }
      )

    {num, _} =
      HackScraper.Repo.insert_all(
        Hackathon,
        maps,
        placeholders: placeholders,
        on_conflict: {:replace_all_except, [:id, :url, :start_date, :series, :inserted_at]},
        conflict_target: [:url, :start_date]
      )

    num
  end
end
