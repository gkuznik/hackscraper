defmodule HackScraper.Scrapers do
  @moduledoc """
  The Scraper context.
  """

  import Ecto.Query, warn: false
  alias HackScraper.Worker.Scheduler
  alias HackScraper.Repo

  alias HackScraper.Scrapers.Scraper

  @doc """
  Returns the list of scrapers.

  ## Examples

      iex> list_scrapers()
      [%Scraper{}, ...]

  """
  def list_scrapers do
    Repo.all(Scraper)
  end

  def list_scrapers_for_scheduling do
    Repo.all(Scraper |> where([s], s.paused == false))
  end

  @doc """
  Gets a single scraper.

  Raises `Ecto.NoResultsError` if the Scraper does not exist.

  ## Examples

      iex> get_scraper!(123)
      %Scraper{}

      iex> get_scraper!(456)
      ** (Ecto.NoResultsError)

  """
  def get_scraper!(id), do: Repo.get!(Scraper, id)

  @doc """
  Creates a scraper.

  ## Examples

      iex> create_scraper(%{field: value})
      {:ok, %Scraper{}}

      iex> create_scraper(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_scraper(attrs \\ %{}) do
    Repo.transaction(fn ->
      with {:ok, scraper} <-
             %Scraper{}
             |> Scraper.changeset(attrs)
             |> Repo.insert(),
           {:ok, _} <-
             Scheduler.schedule_executions_for_period(scraper) do
        scraper
      else
        {:error, value} -> Repo.rollback(value)
      end
    end)
  end

  @doc """
  Updates a scraper.

  ## Examples

      iex> update_scraper(scraper, %{field: new_value})
      {:ok, %Scraper{}}

      iex> update_scraper(scraper, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_scraper(%Scraper{} = scraper, attrs) do
    Repo.transaction(fn ->
      with {:ok, updated_scraper} <-
             scraper
             |> Scraper.changeset(attrs)
             |> Repo.update(),
           {:ok, _count} <- delete_jobs(scraper),
           {:ok, _} <- Scheduler.schedule_executions_for_period(updated_scraper) do
        updated_scraper
      else
        {:error, value} -> Repo.rollback(value)
      end
    end)
  end

  @doc """
  Deletes a scraper.

  ## Examples

      iex> delete_scraper(scraper)
      {:ok, %Scraper{}}

      iex> delete_scraper(scraper)
      {:error, %Ecto.Changeset{}}

  """
  def delete_scraper(%Scraper{} = scraper) do
    Repo.transaction(fn ->
      with {:ok, deleted_scraper} <- Repo.delete(scraper),
           {:ok, _count} <- delete_jobs(scraper) do
        deleted_scraper
      else
        {:error, value} -> Repo.rollback(value)
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking scraper changes.

  ## Examples

      iex> change_scraper(scraper)
      %Ecto.Changeset{data: %Scraper{}}

  """
  def change_scraper(%Scraper{} = scraper, attrs \\ %{}) do
    Scraper.changeset(scraper, attrs)
  end

  def delete_jobs(%Scraper{id: id}) when is_integer(id) do
    Oban.Job
    |> Ecto.Query.where(state: "scheduled")
    |> Ecto.Query.where(
      [j],
      fragment("?->>'scraper_id' = ?", j.meta, ^to_string(id))
    )
    |> Oban.delete_all_jobs()
  end
end
