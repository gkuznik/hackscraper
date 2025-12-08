defmodule HackScraperWeb.SeriesLive.Show do
  use HackScraperWeb, :live_view

  alias HackScraper.Events

  on_mount {HackScraperWeb.UserAuth, :mount_current_user}

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    series = Events.get_series!(id) |> HackScraper.Repo.preload(:hackathons)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action, series))
     |> assign(:series, series)}
  end

  defp page_title(:show, series), do: "Series: " <> series.name
  defp page_title(:edit, series), do: "Edit " <> series.name
end
