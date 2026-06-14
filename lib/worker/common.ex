defmodule HackScraper.Worker.Common do
  alias HackScraper.Events.Suggestion
  alias HackScraper.Events.Hackathon

  # TODO setup bot accounts, use admin for now
  def user_id, do: 1

  def oban_opts, do: [queue: :scraper, priority: 2, max_attempts: 3]

  defp user_agent do
    host = Application.get_env(:hackscraper, HackScraperWeb.Endpoint)[:url][:host]
    version = Application.spec(:hackscraper, :vsn)

    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko; HackScraper/#{version}; #{host}) Chrome/134.0.0.0 Safari/537.3"
  end

  @workers %{
    "Devpost" =>
      {HackScraper.Worker.Devpost,
       "https://devpost.com/api/hackathons?open_to[]=public&search=munich&status[]=upcoming&status[]=open"},
    "Direct" => {HackScraper.Worker.Direct, ""},
    "Dummy" => {HackScraper.Worker.Dummy, ""},
    "Get Links" => {HackScraper.Worker.GetLinks, ""},
    "Huawei" => {HackScraper.Worker.Huawei, "https://huawei.agorize.com/api/v2/challenges"},
    "LabLab" => {HackScraper.Worker.LabLab, "https://lablab.ai/ai-hackathons"},
    "Luma" =>
      {HackScraper.Worker.Luma,
       "https://api2.luma.com/discover/get-paginated-events?latitude=48.13743&longitude=11.57549&pagination_limit=30&slug=tech"},
    "N3xtcoder" =>
      {HackScraper.Worker.N3xtcoder,
       "https://n3xtcoder.org/api/event-cards?offset=0&sort=desc&pageSize=6&lang=en"},
    "Taikai" => {HackScraper.Worker.Taikai, "https://api.taikai.network/api/graphql"},
    "TUM Think Tank" => {HackScraper.Worker.TUMThinkTank, "https://tumthinktank.de/events/"},
    "TUM Venture Labs" =>
      {HackScraper.Worker.TUMVentureLabs,
       "https://www.tum-venture-labs.de/index.php?p=actions/sprig-core/components/render&eventFormats[]=66989&reset=false&search=&sprig:siteId=9a1761719fed643d2a9161f9bfa109521c7487343e041b2d3541f6f497b907ed1&sprig:id=18f5b0bbf1163c3ee576f32b2b84820f55e7f2099ee44df628295be00ca478d4s-events-list&sprig:component=7b3a1f07361ad5a76557bad89bff243735691e7103956a9201f2c2959b531556&sprig:template=49f84ea3b95926b92ef6f0545f1b9613962135886d4703c8e69d52dcaacc4088events/_event-list"},
    "Unternehmertum" =>
      {HackScraper.Worker.Unternehmertum,
       "https://www.unternehmertum.de/events?filter%5B%5D=9511"}
  }
  @internal_workers %{
    "Luma.AddInfo" => HackScraper.Worker.Luma.AddInfo,
    "TUMVentureLabs.AddInfo" => HackScraper.Worker.TUMVentureLabs.AddInfo
  }

  def workers, do: @workers

  def worker_module(name) when is_binary(name) do
    case Map.fetch(@workers, name) do
      {:ok, {module, _url}} -> module
      :error -> Map.fetch!(@internal_workers, name)
    end
  end

  def worker_url(name) when is_binary(name) do
    @workers[name] |> elem(1)
  end

  def get!(api_url) do
    Req.get!(api_url, http_errors: :raise, user_agent: user_agent())
  end

  def post_json!(api_url, json) do
    Req.post!(api_url, json: json, http_errors: :raise, user_agent: user_agent())
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

  def parse_date(date_string) when is_nil(date_string) or date_string == "" do
    nil
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
          |> Map.put(:updated_at, {:placeholder, :timestamp})
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
