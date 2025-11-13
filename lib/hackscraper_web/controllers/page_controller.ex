defmodule HackScraperWeb.PageController do
  use HackScraperWeb, :controller

  alias HackScraper.Events

  def home(conn, _params) do
    hackathons = Events.list_hackathons_for_home_page(12 + 1)

    render(conn, :home, layout: false, hackathons: hackathons)
  end
end
