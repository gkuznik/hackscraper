defmodule HackScraperWeb.SeriesLive.Index do
  use HackScraperWeb, :live_view

  import HackScraperWeb.LiveAuth
  alias HackScraper.Events
  alias HackScraper.Events.Series

  on_mount {HackScraperWeb.UserAuth, :mount_current_user}

  @impl true
  def handle_params(params, _url, socket) do
    current_user = socket.assigns.current_user
    is_editor = HackScraper.Accounts.can_do?(current_user, :editor)

    if socket.assigns.live_action in [:edit, :new] && !is_editor do
      deny(socket)
    else
      {series, meta} =
        Flop.validate_and_run!(Series, params, for: Series, replace_invalid_params: true)

      socket =
        socket
        |> assign(:meta, meta)
        |> stream(:series, series, reset: true)
        |> assign(:is_editor, is_editor)
        |> apply_action(socket.assigns.live_action, params)

      {:noreply, socket}
    end
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    series = Events.get_series!(id)

    socket
    |> assign(:page_title, "Edit Series " <> series.name)
    |> assign(:series, series)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Series")
    |> assign(:series, %Series{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Series")
    |> assign(:series, nil)
  end

  @impl true
  def handle_info({HackScraperWeb.SeriesLive.FormComponent, {:saved, series}}, socket) do
    {:noreply, stream_insert(socket, :series, series)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    if !socket.assigns.is_editor do
      deny(socket)
    else
      series = Events.get_series!(id)
      {:ok, _} = Events.delete_series(series)

      {:noreply, stream_delete(socket, :series, series)}
    end
  end

  @impl true
  def handle_event("clear-filter", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/series")}
  end

  @impl true
  def handle_event("update-filter", params, socket) do
    params = Map.delete(params, "_target")
    {:noreply, push_patch(socket, to: ~p"/series?#{params}")}
  end
end
