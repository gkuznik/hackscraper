defmodule HackScraperWeb.HackathonLive.Show do
  use HackScraperWeb, :live_view

  alias HackScraper.Events

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    hackathon = Events.get_hackathon!(id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action, hackathon))
     |> assign(:hackathon, hackathon)}
  end

  defp page_title(:show, hackathon), do: "Show Hackathon " <> hackathon.name
  defp page_title(:edit, hackathon), do: "Edit Hackathon " <> hackathon.name
end
