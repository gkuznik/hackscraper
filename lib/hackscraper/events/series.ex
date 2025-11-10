defmodule HackScraper.Events.Series do
  use Ecto.Schema
  import Ecto.Changeset

  schema "series" do
    field :name, :string
    field :description, :string

    has_many :hackathons, HackScraper.Events.Hackathon

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(series, attrs) do
    series
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
  end
end
