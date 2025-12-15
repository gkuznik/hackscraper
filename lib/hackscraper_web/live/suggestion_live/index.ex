defmodule HackScraperWeb.SuggestionLive.Index do
  alias HackScraper.Events.Suggestion
  use HackScraperWeb, :live_view

  import Ecto.Query
  alias HackScraper.Events

  on_mount {HackScraperWeb.UserAuth, :mount_current_user}

  @impl true
  def handle_params(params, _url, socket) do
    user = socket.assigns.current_user

    query =
      if HackScraper.Accounts.can_do?(user, :editor) do
        Suggestion
      else
        from s in Suggestion, where: s.creator_id == ^user.id
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
    user = socket.assigns.current_user
    suggestion = Events.get_suggestion!(id)

    if (user && user.id == suggestion.creator_id) || HackScraper.Accounts.can_do?(user, :editor) do
      {:ok, _} = Events.delete_suggestion(suggestion)

      {:noreply, stream_delete(socket, :suggestions, suggestion)}
    else
      {:noreply, put_flash(socket, :error, "You are not authorized to delete this suggestion.")}
    end
  end
end
