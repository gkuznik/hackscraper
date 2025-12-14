defmodule HackScraperWeb.PageController do
  use HackScraperWeb, :controller

  alias HackScraper.Events

  def home(conn, _params) do
    hackathons = Events.list_hackathons_for_home_page(12 + 1)
    count = Events.count_hackathons()

    render(conn, :home, layout: false, hackathons: hackathons, count: count)
  end
end
