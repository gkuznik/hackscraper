defmodule HackScraperWeb.HackathonLive.Index do
  use HackScraperWeb, :live_view

  import HackScraperWeb.LiveAuth
  alias HackScraper.Events
  alias HackScraper.Events.Hackathon

  on_mount {HackScraperWeb.UserAuth, :mount_current_user}

  @impl true
  def handle_params(params, _url, socket) do
    current_user = socket.assigns.current_user

    if socket.assigns.live_action in [:edit, :new] && !current_user do
      deny(socket)
    else
      {hackathons, meta} =
        Flop.validate_and_run!(Hackathon, params, for: Hackathon, replace_invalid_params: true)

      is_editor = HackScraper.Accounts.can_do?(current_user, :editor)

      socket =
        socket
        |> assign(:meta, meta)
        |> stream(:hackathons, hackathons, reset: true)
        |> assign(:is_editor, is_editor)
        |> apply_action(socket.assigns.live_action, params)

      {:noreply, socket}
    end
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    hackathon = Events.get_hackathon!(id)
    current_user = socket.assigns.current_user
    is_editor = HackScraper.Accounts.can_do?(current_user, :editor)

    suggestion =
      if current_user && !is_editor do
        Events.get_suggestion_by_user_and_hackathon(current_user.id, hackathon.id)
      else
        nil
      end

    socket
    |> assign(:page_title, "Edit Hackathon " <> hackathon.name)
    |> assign(:hackathon, hackathon)
    |> assign(:suggestion, suggestion)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Hackathon")
    |> assign(:hackathon, %Hackathon{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Hackathons")
    |> assign(:hackathon, nil)
  end

  @impl true
  def handle_info({HackScraperWeb.HackathonLive.FormComponent, {:saved, hackathon}}, socket) do
    {:noreply, stream_insert(socket, :hackathons, hackathon)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    if !socket.assigns.is_editor do
      deny(socket)
    else
      hackathon = Events.get_hackathon!(id)
      {:ok, _} = Events.delete_hackathon(hackathon)

      {:noreply, stream_delete(socket, :hackathons, hackathon)}
    end
  end
end
