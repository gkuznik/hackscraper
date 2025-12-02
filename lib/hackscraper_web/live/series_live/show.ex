defmodule HackScraperWeb.SeriesLive.Show do
  use HackScraperWeb, :live_view

  alias HackScraper.Events

  on_mount {HackScraperWeb.UserAuth, :mount_current_user}

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:series, Events.get_series!(id) |> HackScraper.Repo.preload(:hackathons))}
  end

  defp page_title(:show), do: "Show Series"
  defp page_title(:edit), do: "Edit Series"
end
