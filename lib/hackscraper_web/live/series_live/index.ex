defmodule HackScraperWeb.SeriesLive.Index do
  use HackScraperWeb, :live_view

  alias HackScraper.Events
  alias HackScraper.Events.Series

  @impl true
  def handle_params(params, _url, socket) do
    {series, meta} =
      Flop.validate_and_run!(Series, params, for: Series, replace_invalid_params: true)

    socket =
      socket
      |> assign(:meta, meta)
      |> stream(:series, series, reset: true)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
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
    series = Events.get_series!(id)
    {:ok, _} = Events.delete_series(series)

    {:noreply, stream_delete(socket, :series, series)}
  end
end
