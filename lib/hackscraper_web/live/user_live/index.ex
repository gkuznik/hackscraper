defmodule HackScraperWeb.UserLive.Index do
  use HackScraperWeb, :live_view

  alias HackScraper.Accounts
  alias HackScraper.Accounts.User

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    user = Accounts.get_user!(id)

    socket
    |> assign(:page_title, "Edit User " <> user.name)
    |> assign(:user, user)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New User")
    |> assign(:user, %User{})
  end

  defp apply_action(socket, :index, params) do
    {users, meta} = Flop.validate_and_run!(User, params, for: User, replace_invalid_params: true)

    socket
    |> assign(:meta, meta)
    |> stream(:users, users, reset: true)
    |> assign(:page_title, "Listing Users")
    |> assign(:user, nil)
  end

  @impl true
  def handle_info({HackScraperWeb.UserLive.FormComponent, {:saved, user}}, socket) do
    {:noreply, stream_insert(socket, :user_collection, user)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    {:ok, _} = Accounts.delete_user(user)

    {:noreply, stream_delete(socket, :user_collection, user)}
  end
end
