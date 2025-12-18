defmodule HackScraperWeb.SuggestionLive.Show do
  use HackScraperWeb, :live_view

  import HackScraperWeb.LiveAuth
  alias HackScraper.Events

  on_mount {HackScraperWeb.UserAuth, :mount_current_user}

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    suggestion = Events.get_suggestion_with_creator!(id)
    current_user = socket.assigns.current_user
    is_editor = HackScraper.Accounts.can_do?(current_user, :editor)

    if current_user.id != suggestion.creator_id && !is_editor do
      deny(socket)
    else
      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action, suggestion))
       |> assign(:suggestion, suggestion)}
    end
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
