defmodule HackScraperWeb.PageController do
  use HackScraperWeb, :controller

  alias HackScraper.Events

  def home(conn, _params) do
    hackathons = Events.upcoming_hackathons(12)
    count = Events.count_hackathons()

    render(conn, :home, layout: false, hackathons: hackathons, count: count)
  end

  def about(conn, _params) do
    render(conn, :about, layout: false)
  end
end
