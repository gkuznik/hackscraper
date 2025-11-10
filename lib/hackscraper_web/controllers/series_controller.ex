defmodule HackScraperWeb.SeriesController do
  use HackScraperWeb, :controller

  alias HackScraper.Events
  alias HackScraper.Events.Series

  def index(conn, _params) do
    series = Events.list_series()
    render(conn, :index, series_collection: series)
  end

  def new(conn, _params) do
    changeset = Events.change_series(%Series{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"series" => series_params}) do
    case Events.create_series(series_params) do
      {:ok, series} ->
        conn
        |> put_flash(:info, "Series created successfully.")
        |> redirect(to: ~p"/series/#{series}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    series = Events.get_series!(id)
    render(conn, :show, series: series)
  end

  def edit(conn, %{"id" => id}) do
    series = Events.get_series!(id)
    changeset = Events.change_series(series)
    render(conn, :edit, series: series, changeset: changeset)
  end

  def update(conn, %{"id" => id, "series" => series_params}) do
    series = Events.get_series!(id)

    case Events.update_series(series, series_params) do
      {:ok, series} ->
        conn
        |> put_flash(:info, "Series updated successfully.")
        |> redirect(to: ~p"/series/#{series}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, series: series, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    series = Events.get_series!(id)
    {:ok, _series} = Events.delete_series(series)

    conn
    |> put_flash(:info, "Series deleted successfully.")
    |> redirect(to: ~p"/series")
  end
end
