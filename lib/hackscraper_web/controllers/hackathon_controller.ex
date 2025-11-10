defmodule HackScraperWeb.HackathonController do
  use HackScraperWeb, :controller

  alias HackScraper.Events
  alias HackScraper.Events.Hackathon

  def index(conn, _params) do
    hackathons = Events.list_hackathons()
    render(conn, :index, hackathons: hackathons)
  end

  def new(conn, _params) do
    changeset = Events.change_hackathon(%Hackathon{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"hackathon" => hackathon_params}) do
    case Events.create_hackathon(hackathon_params) do
      {:ok, hackathon} ->
        conn
        |> put_flash(:info, "Hackathon created successfully.")
        |> redirect(to: ~p"/hackathons/#{hackathon}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    hackathon = Events.get_hackathon!(id)
    render(conn, :show, hackathon: hackathon)
  end

  def edit(conn, %{"id" => id}) do
    hackathon = Events.get_hackathon!(id)
    changeset = Events.change_hackathon(hackathon)
    render(conn, :edit, hackathon: hackathon, changeset: changeset)
  end

  def update(conn, %{"id" => id, "hackathon" => hackathon_params}) do
    hackathon = Events.get_hackathon!(id)

    case Events.update_hackathon(hackathon, hackathon_params) do
      {:ok, hackathon} ->
        conn
        |> put_flash(:info, "Hackathon updated successfully.")
        |> redirect(to: ~p"/hackathons/#{hackathon}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, hackathon: hackathon, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    hackathon = Events.get_hackathon!(id)
    {:ok, _hackathon} = Events.delete_hackathon(hackathon)

    conn
    |> put_flash(:info, "Hackathon deleted successfully.")
    |> redirect(to: ~p"/hackathons")
  end
end
