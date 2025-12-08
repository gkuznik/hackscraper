defmodule HackScraperWeb.SuggestionLive.Show do
  use HackScraperWeb, :live_view

  alias HackScraper.Events

  on_mount {HackScraperWeb.UserAuth, :mount_current_user}

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    suggestion = Events.get_suggestion!(id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action, suggestion))
     |> assign(:suggestion, suggestion)}
  end

  @impl true
  def handle_info({HackScraperWeb.HackathonLive.FormComponent, {:saved, hackathon}}, socket) do
    {:ok, _} = Events.delete_suggestion(socket.assigns.suggestion)

    {:noreply,
     put_flash(socket, :info, "Suggestion published as Hackathon")
     |> push_navigate(to: ~p"/hackathons/#{hackathon}")}
  end

  defp page_title(:show, suggestion), do: "Suggestion: " <> suggestion.name
  defp page_title(:review, suggestion), do: "Review " <> suggestion.name
end
