defmodule HackScraperWeb.UserLive.Index do
  use HackScraperWeb, :live_view

  import HackScraperWeb.LiveAuth
  alias HackScraper.Accounts
  alias HackScraper.Accounts.User

  on_mount {HackScraperWeb.LiveAuth, :mod}

  @impl true
  def handle_params(params, _url, socket) do
    {users, meta} = Flop.validate_and_run!(User, params, for: User, replace_invalid_params: true)

    socket =
      socket
      |> assign(:meta, meta)
      |> stream(:users, users, reset: true)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    user = Accounts.get_user!(id)
    current_user = socket.assigns.current_user

    if user.role > current_user.role do
      deny(socket) |> elem(1)
    else
      socket
      |> assign(:page_title, "Edit User " <> user.name)
      |> assign(:user, user)
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New User")
    |> assign(:user, %User{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Users")
    |> assign(:user, nil)
  end

  @impl true
  def handle_info({HackScraperWeb.UserLive.FormComponent, {:saved, user}}, socket) do
    {:noreply, stream_insert(socket, :users, user)}
  end

  @impl true
  def handle_event("update-filter", params, socket) do
    params = Map.delete(params, "_target")
    {:noreply, push_patch(socket, to: ~p"/users?#{params}")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    current_user = socket.assigns.current_user

    if user.role > current_user.role do
      deny(socket)
    else
      {:ok, _} = Accounts.delete_user(user)

      {:noreply, stream_delete(socket, :users, user)}
    end
  end
end
