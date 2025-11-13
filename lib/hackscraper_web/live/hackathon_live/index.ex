defmodule HackScraperWeb.HackathonLive.Index do
  use HackScraperWeb, :live_view

  alias HackScraper.Events
  alias HackScraper.Events.Hackathon

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    hackathon = Events.get_hackathon!(id)

    socket
    |> assign(:page_title, "Edit Hackathon " <> hackathon.name)
    |> assign(:hackathon, hackathon)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Hackathon")
    |> assign(:hackathon, %Hackathon{})
  end

  defp apply_action(socket, :index, params) do
    {hackathons, meta} =
      Flop.validate_and_run!(Hackathon, params, for: Hackathon, replace_invalid_params: true)

    socket
    |> assign(:meta, meta)
    |> stream(:hackathons, hackathons, reset: true)
    |> assign(:page_title, "Listing Hackathons")
    |> assign(:hackathon, nil)
  end

  @impl true
  def handle_info({HackScraperWeb.HackathonLive.FormComponent, {:saved, hackathon}}, socket) do
    {:noreply, stream_insert(socket, :hackathons, hackathon)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    hackathon = Events.get_hackathon!(id)
    {:ok, _} = Events.delete_hackathon(hackathon)

    {:noreply, stream_delete(socket, :hackathons, hackathon)}
  end
end
