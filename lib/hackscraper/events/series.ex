defmodule HackScraper.Events.Series do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:name, :url, :description], sortable: [:name, :url]
  }

  schema "series" do
    field :name, :string
    field :description, :string
    field :image, :string
    field :url, :string

    has_many :hackathons, HackScraper.Events.Hackathon

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(series, attrs) do
    series
    |> cast(attrs, [:name, :url, :image, :description])
    |> validate_required([:name, :description])
  end
end
