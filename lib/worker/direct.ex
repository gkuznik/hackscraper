defmodule HackScraper.Worker.Direct do
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

  def scrape(%{"url" => url}) do
    Logger.info("Running direct scraper: #{url}...")
    html = get!(url).body

    {_result, globals} =
      Pythonx.eval(
        """
        # Elixir strings are bytes
        url = url.decode("utf-8")

        from urllib.parse import urljoin
        from trafilatura import extract_metadata

        # use wrong outputformat type to skip date parsing
        date_config = {"outputformat": 1, "original_date": True, "extensive_search": False, "max_date": "2024-12-10"}
        meta = extract_metadata(html, url, date_config=date_config)
        url = meta.url
        image = urljoin(url, meta.image) if meta.image else None
        title = meta.title
        description = meta.description
        """,
        %{"html" => html, "url" => url}
      )

    text =
      html
      |> Floki.parse_document!()
      |> Floki.text(sep: " ")

    {name, description} = split_title(Pythonx.decode(globals["title"]))

    suggestion = %{
      url: Pythonx.decode(globals["url"]) || url,
      image: Pythonx.decode(globals["image"]),
      name: name,
      description: Pythonx.decode(globals["description"]) || description,
      date_hint: extract_dates(text)
    }

    {:suggestions, [suggestion]}
  end
end
