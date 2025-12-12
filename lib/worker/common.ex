defmodule HackScraper.Worker.Common do
  alias HackScraper.Events.Suggestion
  alias HackScraper.Events.Hackathon

  # TODO setup bot accounts, use admin for now
  def user_id, do: 1

  # TODO retry attempts to 3 for prod
  def oban_opts, do: [queue: :scraper, priority: 2, max_attempts: 1]

  @user_agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko; HackScraper/#{Application.spec(:hackscraper, :vsn)}; hack.gabriels.cloud) Chrome/134.0.0.0 Safari/537.3"

  @workers %{
    "Devpost" => HackScraper.Worker.Devpost,
    "Direct" => HackScraper.Worker.Direct,
    "Dummy" => HackScraper.Worker.Dummy,
    "Get Links" => HackScraper.Worker.GetLinks,
    "Huawei" => HackScraper.Worker.Huawei,
    "Luma" => HackScraper.Worker.Luma,
    "N3xtcoder" => HackScraper.Worker.N3xtcoder,
    "Taikai" => HackScraper.Worker.Taikai,
    "TUM Venture Labs" => HackScraper.Worker.TUMVentureLabs,
    "Unternehmertum" => HackScraper.Worker.Unternehmertum
  }
  def workers, do: @workers

  def worker_module(name) when is_binary(name) do
    @workers[name]
  end

  def get!(api_url) do
    Req.get!(api_url, http_errors: :raise, user_agent: @user_agent)
  end

  def post_json!(api_url, json) do
    Req.post!(api_url, json: json, http_errors: :raise, user_agent: @user_agent)
  end

  def split_title(title) do
    parts =
      title
      |> String.replace("–", "-")
      |> String.split(" - ", parts: 2)

    name = parts |> List.first() |> String.trim()
    description = if length(parts) > 1, do: parts |> List.last() |> String.trim(), else: nil

    {name, description}
  end

  def parse_date(date_string) do
    {:ok, date, _} = DateTime.from_iso8601(date_string)
    DateTime.truncate(date, :second)
  end

  @doc """
  hackathon with same URL -> human already checked it out -> no suggestion
  suggestion with same URL created by us -> update fields

  returns number of inserted/updated suggestions
  """
  def upsert_suggestions([]), do: 0

  def upsert_suggestions(suggestions) do
    import Ecto.Query

    new_suggestions =
      Enum.reject(suggestions, fn %{url: url} ->
        HackScraper.Repo.exists?(from h in Hackathon, where: h.url == ^url)
      end)

    timestamp = DateTime.utc_now(:second)
    placeholders = %{timestamp: timestamp}

    with_placeholder =
      Enum.map(
        new_suggestions,
        fn s ->
          Map.put(s, :inserted_at, {:placeholder, :timestamp})
          |> Map.put(:creator_id, user_id())
        end
      )

    {num, _} =
      HackScraper.Repo.insert_all(
        Suggestion,
        with_placeholder,
        placeholders: placeholders,
        on_conflict: {:replace_all_except, [:id, :creator_id, :url, :start_date]},
        conflict_target: [:creator_id, :url, :start_date]
      )

    num
  end

  @doc """
  hackathon with same URL and start date -> human already checked it out -> don't insert/update

  returns number of inserted/updated hackathons
  """
  def upsert_hackathons([]), do: 0

  def upsert_hackathons(hackathons) do
    timestamp = DateTime.utc_now(:second)
    placeholders = %{timestamp: timestamp}

    with_placeholder =
      Enum.map(
        hackathons,
        fn h ->
          Map.put(h, :inserted_at, {:placeholder, :timestamp})
          |> Map.put(:updated_at, {:placeholder, :timestamp})
        end
      )

    {num, _} =
      HackScraper.Repo.insert_all(
        Hackathon,
        with_placeholder,
        placeholders: placeholders,
        on_conflict: :nothing,
        conflict_target: [:url, :start_date]
      )

    num
  end
end
