defmodule HackScraperWeb.LiveAuth do
  use HackScraperWeb, :verified_routes

  import Phoenix.LiveView
  alias HackScraper.Accounts

  def on_mount(role, _params, _session, socket) do
    if Accounts.can_do?(socket.assigns[:current_user], role) do
      {:cont, socket}
    else
      socket =
        socket
        |> put_flash(:error, "You are not authorized to access this page.")
        |> redirect(to: "/", status: 301)

      {:halt, socket}
    end
  end

  def deny(socket) do
    {:noreply,
     socket
     |> put_flash(:error, "You are not authorized to access this page.")
     |> redirect(to: "/", status: 301)}
  end
end
