defmodule HackScraperWeb.ScraperLive.Show do
  use HackScraperWeb, :live_view

  alias HackScraper.Worker

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    scraper = Worker.get_scraper!(id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action, scraper))
     |> assign(:scraper, scraper)}
  end

  defp page_title(:show, scraper), do: "Show Scraper " <> scraper.name
  defp page_title(:edit, scraper), do: "Edit Scraper " <> scraper.name
end
