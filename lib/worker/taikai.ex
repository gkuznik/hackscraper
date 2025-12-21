defmodule HackScraper.Worker.Taikai do
  use Oban.Worker

  import HackScraper.Worker.Common

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"url" => url}}) do
    Logger.info("Running Taikai Network scraper...")

    query = %{
      "operationName" => "ALL_CHALLENGES_QUERY",
      "variables" => %{
        "sortBy" => %{
          "order" => "desc"
        },
        "page" => 1
      },
      "query" =>
        "query ALL_CHALLENGES_QUERY($sortBy: ChallengeOrderByWithRelationInput, $page: Int) {  challenges(where: {publishInfo: {state: {equals: ACTIVE}}}, page: $page, orderBy: $sortBy) {\n    id\n    name\n    isClosed\n    shortDescription\n    cardImageFile {\n      id\n      url\n      __typename\n    }\n    organization {\n      id\n      name\n      slug\n      __typename\n    }\n    steps {\n      id\n      startDate\n      __typename\n    }\n    currentStep {\n      id\n      name\n      startDate\n      __typename\n    }\n    slug\n    order\n    __typename\n  }\n}"
    }

    challenges = post_json!(url, query).body["data"]["challenges"]

    hackathons =
      Enum.map(challenges, fn hack ->
        org_slug = hack["organization"]["slug"]
        hack_slug = hack["slug"]
        card_image = hack["cardImageFile"]["url"]

        dates =
          hack["steps"]
          |> Enum.map(fn step -> parse_date(step["startDate"]) end)
          |> Enum.sort(DateTime)

        %{
          url: "https://taikai.network/#{org_slug}/hackathons/#{hack_slug}",
          image: card_image,
          name: hack["name"],
          description: hack["shortDescription"],
          start_date: List.first(dates),
          end_date: List.last(dates)
        }
      end)

    Logger.info("Found #{length(hackathons)} hackathons")

    num = upsert_hackathons(hackathons)
    Logger.info("Created/updated #{num} hackathons")
  end
end
