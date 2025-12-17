defmodule HackScraperWeb.HackathonLive.Show do
  use HackScraperWeb, :live_view

  import HackScraperWeb.LiveAuth
  alias HackScraper.Events

  on_mount {HackScraperWeb.UserAuth, :mount_current_user}

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    authorized socket, [:edit], :user do
      hackathon = Events.get_hackathon!(id)
      current_user = socket.assigns.current_user
      is_editor = HackScraper.Accounts.can_do?(current_user, :editor)

      suggestion =
        if current_user && !is_editor do
          Events.get_suggestion_by_user_and_hackathon(current_user.id, hackathon.id)
        else
          nil
        end

      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action, hackathon))
       |> assign(:hackathon, hackathon)
       |> assign(:is_editor, is_editor)
       |> assign(:suggestion, suggestion)}
    end
  end

  @impl true
  def handle_info({HackScraperWeb.HackathonLive.FormComponent, {:saved, _hackathon}}, socket) do
    {:noreply, socket}
  end

  defp page_title(:show, hackathon), do: "Hackathon: " <> hackathon.name
  defp page_title(:edit, hackathon), do: "Edit " <> hackathon.name
end
