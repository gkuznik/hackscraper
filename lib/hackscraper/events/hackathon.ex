defmodule HackScraper.Events.Hackathon do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:name, :url, :description, :location],
    sortable: [:name, :url, :location, :start_date, :end_date]
  }

  schema "hackathons" do
    field :name, :string
    field :description, :string
    field :location, :string
    field :image, :string
    field :url, :string
    field :start_date, :utc_datetime
    field :end_date, :utc_datetime
    belongs_to :series, HackScraper.Events.Series

    has_many :suggestions, HackScraper.Events.Suggestion

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(hackathon, attrs) do
    hackathon
    |> cast(attrs, [
      :name,
      :url,
      :image,
      :description,
      :location,
      :start_date,
      :end_date,
      :series_id
    ])
    |> validate_required([:name, :url, :start_date, :end_date])
    |> unsafe_validate_unique([:url, :start_date], HackScraper.Repo)
    |> unique_constraint([:url, :start_date])
  end
end
