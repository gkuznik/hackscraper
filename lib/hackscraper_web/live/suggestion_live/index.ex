defmodule HackScraperWeb.SuggestionLive.Index do
  alias HackScraper.Events.Suggestion
  use HackScraperWeb, :live_view

  alias HackScraper.Events

  @impl true
  def handle_params(params, _url, socket) do
    {suggestions, meta} =
      Flop.validate_and_run!(Suggestion, params,
        for: Suggestion,
        replace_invalid_params: true
      )

    socket =
      socket
      |> assign(:meta, meta)
      |> stream(:suggestions, suggestions, reset: true)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp apply_action(socket, :review, %{"id" => id}) do
    socket
    |> assign(:page_title, "Review Suggestion")
    |> assign(:suggestion, Events.get_suggestion!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Suggestions")
    |> assign(:last_suggestion, socket.assigns[:suggestion])
    |> assign(:suggestion, nil)
  end

  @impl true
  def handle_info({HackScraperWeb.HackathonLive.FormComponent, {:saved, _hackathon}}, socket) do
    suggestion = socket.assigns.suggestion || socket.assigns.last_suggestion
    {:ok, _} = Events.delete_suggestion(suggestion)

    {:noreply, stream_delete(socket, :suggestions, suggestion)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    suggestion = Events.get_suggestion!(id)
    {:ok, _} = Events.delete_suggestion(suggestion)

    {:noreply, stream_delete(socket, :suggestions, suggestion)}
  end
end
