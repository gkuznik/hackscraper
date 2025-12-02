defmodule HackScraperWeb.UserLive.Show do
  use HackScraperWeb, :live_view

  alias HackScraper.Accounts

  on_mount {HackScraperWeb.UserAuth, :mount_current_user}

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    user = Accounts.get_user!(id)

    {:noreply,
     socket
     |> assign(:user, user)
     |> assign(:page_title, page_title(socket.assigns.live_action, user))}
  end

  defp page_title(:show, user), do: "User " <> user.name
  defp page_title(:edit, user), do: "Edit User " <> user.name
end
