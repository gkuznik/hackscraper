defmodule HackScraper.Events do
  @moduledoc """
  The Events context.
  """

  import Ecto.Query, warn: false
  alias HackScraper.Repo

  alias HackScraper.Events.Series

  @doc """
  Returns the list of series.

  ## Examples

      iex> list_series()
      [%Series{}, ...]

  """
  def list_series do
    Repo.all(Series)
  end

  @doc """
  Gets a single series.

  Raises `Ecto.NoResultsError` if the Series does not exist.

  ## Examples

      iex> get_series!(123)
      %Series{}

      iex> get_series!(456)
      ** (Ecto.NoResultsError)

  """
  def get_series!(id), do: Repo.get!(Series, id)

  @doc """
  Creates a series.

  ## Examples

      iex> create_series(%{field: value})
      {:ok, %Series{}}

      iex> create_series(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_series(attrs \\ %{}) do
    %Series{}
    |> Series.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a series.

  ## Examples

      iex> update_series(series, %{field: new_value})
      {:ok, %Series{}}

      iex> update_series(series, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_series(%Series{} = series, attrs) do
    series
    |> Series.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a series.

  ## Examples

      iex> delete_series(series)
      {:ok, %Series{}}

      iex> delete_series(series)
      {:error, %Ecto.Changeset{}}

  """
  def delete_series(%Series{} = series) do
    Repo.delete(series)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking series changes.

  ## Examples

      iex> change_series(series)
      %Ecto.Changeset{data: %Series{}}

  """
  def change_series(%Series{} = series, attrs \\ %{}) do
    Series.changeset(series, attrs)
  end

  alias HackScraper.Events.Hackathon

  @doc """
  Returns the list of hackathons.

  ## Examples

      iex> list_hackathons()
      [%Hackathon{}, ...]

  """
  def list_hackathons() do
    Repo.all(Hackathon) |> Repo.preload(:series)
  end

  def list_hackathons_for_home_page(limit) do
    Repo.all(from h in Hackathon, order_by: [desc: h.end_date], limit: ^limit)
    |> Repo.preload(:series)
  end

  @doc """
  Gets a single hackathon.

  Raises `Ecto.NoResultsError` if the Hackathon does not exist.

  ## Examples

      iex> get_hackathon!(123)
      %Hackathon{}

      iex> get_hackathon!(456)
      ** (Ecto.NoResultsError)

  """
  def get_hackathon!(id), do: Repo.get!(Hackathon, id) |> Repo.preload(:series)

  @doc """
  Creates a hackathon.

  ## Examples

      iex> create_hackathon(%{field: value})
      {:ok, %Hackathon{}}

      iex> create_hackathon(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_hackathon(attrs \\ %{}) do
    %Hackathon{}
    |> Hackathon.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a hackathon.

  ## Examples

      iex> update_hackathon(hackathon, %{field: new_value})
      {:ok, %Hackathon{}}

      iex> update_hackathon(hackathon, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_hackathon(%Hackathon{} = hackathon, attrs) do
    hackathon
    |> Hackathon.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a hackathon.

  ## Examples

      iex> delete_hackathon(hackathon)
      {:ok, %Hackathon{}}

      iex> delete_hackathon(hackathon)
      {:error, %Ecto.Changeset{}}

  """
  def delete_hackathon(%Hackathon{} = hackathon) do
    Repo.delete(hackathon)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking hackathon changes.

  ## Examples

      iex> change_hackathon(hackathon)
      %Ecto.Changeset{data: %Hackathon{}}

  """
  def change_hackathon(%Hackathon{} = hackathon, attrs \\ %{}) do
    Hackathon.changeset(hackathon, attrs)
  end

  alias HackScraper.Events.Suggestion

  @doc """
  Returns the list of suggestions.

  ## Examples

      iex> list_suggestions()
      [%Suggestion{}, ...]

  """
  def list_suggestions do
    Repo.all(Suggestion)
  end

  @doc """
  Gets a single suggestion.

  Raises `Ecto.NoResultsError` if the Suggestion does not exist.

  ## Examples

      iex> get_suggestion!(123)
      %Suggestion{}

      iex> get_suggestion!(456)
      ** (Ecto.NoResultsError)

  """
  def get_suggestion!(id), do: Repo.get!(Suggestion, id)

  @doc """
  Creates a suggestion.

  ## Examples

      iex> create_suggestion(%{field: value})
      {:ok, %Suggestion{}}

      iex> create_suggestion(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_suggestion(attrs \\ %{}) do
    %Suggestion{}
    |> Suggestion.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a suggestion.

  ## Examples

      iex> delete_suggestion(suggestion)
      {:ok, %Suggestion{}}

      iex> delete_suggestion(suggestion)
      {:error, %Ecto.Changeset{}}

  """
  def delete_suggestion(%Suggestion{} = suggestion) do
    Repo.delete(suggestion)
  end
end
