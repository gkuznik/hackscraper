defmodule HackScraper.Worker.Scraper do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:name, :url, :paused], sortable: [:name, :url, :schedule]
  }

  schema "scrapers" do
    field :name, :string
    field :url, :string
    field :schedule, :string
    field :paused, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(scraper, attrs) do
    scraper
    |> cast(attrs, [:name, :schedule, :url, :paused])
    |> validate_required([:name, :schedule])
    |> unique_constraint(:name)
  end
end
