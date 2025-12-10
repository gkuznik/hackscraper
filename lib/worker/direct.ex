defmodule HackScraper.Worker.Direct do
  use Oban.Worker

  import HackScraper.Worker.Common

  require Logger

  @date_pattern [
    # 2024-12-10
    ~r/\d{4}-\d{2}-\d{2}/,
    # 10.12.2024
    ~r/\d{1,2}\.\d{1,2}\.\d{4}/,
    # 12/10/2024
    ~r/\d{1,2}\/\d{1,2}\/\d{4}/,
    # 2024/12/10
    ~r/\d{4}\/\d{1,2}\/\d{1,2}/,
    # Dec[ember] 10, 2024
    ~r/\b\w{3,9}\s+\d{1,2},?\s+\d{4}\b/,
    # Dec[ember] 10-12, 2024
    ~r/\b\w{3,9}\s+\d{1,2}\s*-\s*\d{1,2},?\s+\d{4}\b/,
    # Dec 10, 2024 - Jan 10, 2025
    ~r/\b\w{3,9}\s+\d{1,2},\s+\d{4}\s+-\s+\w{3,9}\s+\d{1,2},\s+\d{4}\b/
  ]

  defp extract_dates(text) do
    @date_pattern
    |> Enum.flat_map(fn pattern -> Regex.scan(pattern, text) end)
    |> List.flatten()
    |> Enum.join(" | ")
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"url" => url}}) do
    Logger.info("Running direct scraper", url: url)

    html = get!(url).body

    {_result, globals} =
      Pythonx.eval(
        """
        from urllib.parse import urljoin
        from trafilatura import extract_metadata

        # use wrong outputformat type to skip date parsing
        date_config = {"outputformat": 1, "original_date": True, "extensive_search": False, "max_date": "2024-12-10"}
        # fix Elixir to Python type issues
        meta = extract_metadata(html, str(url), date_config=date_config)
        url = meta.url or str(url)
        image = urljoin(url, meta.image) if meta.image else None

        _parts = meta.title.replace("–", "-").split(" - ", 1)
        name = _parts[0].strip()
        description = meta.description or (_parts[1].strip() if len(_parts) > 1 else None)
        """,
        %{"html" => html, "url" => url}
      )

    # todo ask cuz of Elixir to Python type issues
    # fix b'<string>' being added

    text =
      html
      |> Floki.parse_document!()
      |> Floki.text(sep: " ")

    suggestion = %{
      creator_id: user_id(),
      url: Pythonx.decode(globals["url"]),
      image: Pythonx.decode(globals["image"]),
      name: Pythonx.decode(globals["name"]),
      description: Pythonx.decode(globals["description"]),
      date_hint: extract_dates(text)
    }

    num = upsert_suggestions([suggestion])
    Logger.info("Created #{num} suggestion")
  end
end
