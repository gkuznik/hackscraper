defmodule HackScraper.Events.Series do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    sortable: [:name, :url],
    filterable: [:name, :url, :description],
    adapter_opts: [
      compound_fields: [text: [:name, :url, :description]]
    ]
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
    |> unsafe_validate_unique(:name, HackScraper.Repo)
    |> unique_constraint(:name)
  end
end
