defmodule HackScraper.Events.Suggestion do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:name, :url, :description, :location],
    sortable: [:name, :url, :start_date, :end_date]
  }

  schema "suggestions" do
    field :name, :string
    field :description, :string
    field :location, :string
    field :image, :string
    field :url, :string
    field :date, :string
    field :start_date, :utc_datetime
    field :end_date, :utc_datetime
    field :series_id, :id

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(suggestion, attrs) do
    suggestion
    |> cast(attrs, [:name, :url, :image, :description, :location, :date, :start_date, :end_date])
    |> validate_required([:name, :url])
    |> unsafe_validate_unique(:url, HackScraper.Repo)
    |> unique_constraint(:url)
  end
end
