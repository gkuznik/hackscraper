defmodule HackScraperWeb.UserLive.Show do
  use HackScraperWeb, :live_view

  import HackScraperWeb.LiveAuth
  alias HackScraper.Accounts

  on_mount {HackScraperWeb.LiveAuth, :mod}

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    user = Accounts.get_user!(id)
    current_user = socket.assigns.current_user

    if socket.assigns.live_action == :edit && user.role > current_user.role do
      deny(socket)
    else
      {:noreply,
       socket
       |> assign(:user, user)
       |> assign(:page_title, page_title(socket.assigns.live_action, user))}
    end
  end

  defp page_title(:show, user), do: "User: " <> user.name
  defp page_title(:edit, user), do: "Edit User " <> user.name
end
