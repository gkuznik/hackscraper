defmodule HackScraperWeb.ScraperLive.Show do
  use HackScraperWeb, :live_view

  alias HackScraper.Scrapers

  on_mount {HackScraperWeb.UserAuth, :mount_current_user}

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    scraper = Scrapers.get_scraper!(id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action, scraper))
     |> assign(:scraper, scraper)}
  end

  defp page_title(:show, scraper), do: "Scraper: #{scraper.id}"
  defp page_title(:edit, scraper), do: "Edit Scraper #{scraper.id}"
end
