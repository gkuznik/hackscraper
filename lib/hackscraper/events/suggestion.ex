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
    field :date_hint, :string
    field :start_date, :utc_datetime
    field :end_date, :utc_datetime
    belongs_to :series, HackScraper.Events.Series

    belongs_to :creator, HackScraper.Accounts.User
    belongs_to :hackathon, HackScraper.Events.Hackathon

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(suggestion, attrs) do
    suggestion
    |> cast(attrs, [
      :name,
      :url,
      :image,
      :description,
      :location,
      :date_hint,
      :start_date,
      :end_date,
      :series_id,
      :creator_id,
      :hackathon_id
    ])
    |> validate_required([:name, :url])
    |> unsafe_validate_unique([:creator_id, :hackathon_id], HackScraper.Repo)
    |> unique_constraint([:creator_id, :hackathon_id])
    |> unsafe_validate_unique([:creator_id, :url, :start_date], HackScraper.Repo)
    |> unique_constraint([:creator_id, :url, :start_date])
  end
end
