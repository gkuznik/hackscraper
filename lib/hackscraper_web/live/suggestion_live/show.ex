defmodule HackScraperWeb.SuggestionLive.Show do
  use HackScraperWeb, :live_view

  alias HackScraper.Events

  on_mount {HackScraperWeb.UserAuth, :mount_current_user}

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:suggestion, Events.get_suggestion!(id))}
  end

  defp page_title(:show), do: "Show Suggestion"
  defp page_title(:review), do: "Review Suggestion"
end
