defmodule HackScraperWeb.HackathonController do
  use HackScraperWeb, :controller

  alias HackScraper.Events
  alias HackScraper.Events.Hackathon

  def index(conn, _params) do
    hackathons = Events.list_hackathons()
    render(conn, :index, hackathons: hackathons, page_title: "All Hackathons")
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
    render(conn, :show, hackathon: hackathon, page_title: hackathon.name)
  end

  def edit(conn, %{"id" => id}) do
    hackathon = Events.get_hackathon!(id)
    changeset = Events.change_hackathon(hackathon)
    render(conn, :edit, hackathon: hackathon, page_title: "Edit " <> hackathon.name, changeset: changeset)
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

  def series_opts(changeset) do
    existing_series = Ecto.Changeset.get_change(changeset, :series)
    existing_id = if existing_series, do: existing_series.data.id, else: nil

    for cat <- HackScraper.Events.list_series() do
      [key: cat.name, value: cat.id, selected: cat.id == existing_id]
    end
  end
end
