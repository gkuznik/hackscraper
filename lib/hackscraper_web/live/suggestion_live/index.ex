defmodule HackScraperWeb.SuggestionLive.Index do
  alias HackScraper.Events.Suggestion
  use HackScraperWeb, :live_view

  import Ecto.Query
  import HackScraperWeb.LiveAuth
  alias HackScraper.Events

  @impl true
  def handle_params(params, _url, socket) do
    current_user = socket.assigns.current_user
    is_editor = HackScraper.Accounts.can_do?(current_user, :editor)

    query =
      if is_editor do
        Suggestion
      else
        from s in Suggestion, where: s.creator_id == ^current_user.id
      end

    {suggestions, meta} =
      Flop.validate_and_run!(query, params,
        for: Suggestion,
        replace_invalid_params: true
      )

    socket =
      socket
      |> assign(:meta, meta)
      |> stream(:suggestions, suggestions, reset: true)
      |> assign(:is_editor, is_editor)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp apply_action(socket, :review, %{"id" => id}) do
    suggestion = Events.get_suggestion!(id)
    user = socket.assigns.current_user

    if user.id != suggestion.creator_id && !socket.assigns.is_editor do
      deny(socket) |> elem(1)
    else
      socket
      |> assign(:page_title, "Review Suggestion")
      |> assign(:suggestion, suggestion)
    end
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
    user = socket.assigns.current_user

    if user.id != suggestion.creator_id && !socket.assigns.is_editor do
      deny(socket)
    else
      {:ok, _} = Events.delete_suggestion(suggestion)

      {:noreply, stream_delete(socket, :suggestions, suggestion)}
    end
  end

  @impl true
  def handle_event("clear-filter", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/suggestions")}
  end

  @impl true
  def handle_event("update-filter", params, socket) do
    params = Map.delete(params, "_target")
    {:noreply, push_patch(socket, to: ~p"/suggestions?#{params}")}
  end
end
