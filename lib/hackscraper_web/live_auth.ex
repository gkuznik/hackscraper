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

  defmacro authorized(socket, actions, role, do: block) do
    quote do
      if unquote(socket).assigns.live_action in unquote(actions) and
           !HackScraper.Accounts.can_do?(
             unquote(socket).assigns[:current_user],
             unquote(role)
           ) do
        {:noreply,
         unquote(socket)
         |> Phoenix.LiveView.put_flash(:error, "You are not authorized to access this page.")
         |> Phoenix.LiveView.redirect(to: "/", status: 301)}
      else
        unquote(block)
      end
    end
  end
end
