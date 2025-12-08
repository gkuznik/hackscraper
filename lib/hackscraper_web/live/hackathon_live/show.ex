defmodule HackScraperWeb.HackathonLive.Show do
  use HackScraperWeb, :live_view

  alias HackScraper.Events

  on_mount {HackScraperWeb.UserAuth, :mount_current_user}

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    hackathon = Events.get_hackathon!(id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action, hackathon))
     |> assign(:hackathon, hackathon)}
  end

  defp page_title(:show, hackathon), do: "Hackathon: " <> hackathon.name
  defp page_title(:edit, hackathon), do: "Edit " <> hackathon.name
end
