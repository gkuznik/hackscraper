defmodule HackScraper.Scrapers.Scraper do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:text, :paused],
    sortable: [:worker, :name, :schedule],
    adapter_opts: [
      compound_fields: [text: [:name, :worker, :url]]
    ]
  }

  schema "scrapers" do
    field :name, :string
    field :worker, :string
    field :url, :string
    field :schedule, :string
    field :paused, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(scraper, attrs) do
    scraper
    |> cast(attrs, [:name, :worker, :schedule, :url, :paused])
    |> validate_required([:name, :worker, :schedule])
    |> validate_worker()
    |> validate_schedule()
    |> unsafe_validate_unique(:name, HackScraper.Repo)
    |> unique_constraint(:name)
    |> unsafe_validate_unique(:url, HackScraper.Repo)
    |> unique_constraint(:url)
  end

  defp validate_worker(changeset) do
    changeset
    |> validate_inclusion(
      :worker,
      HackScraper.Worker.Common.workers() |> Map.keys()
    )
  end

  defp validate_schedule(changeset) do
    case get_field(changeset, :schedule) do
      nil ->
        changeset

      schedule ->
        case Oban.Plugins.Cron.parse(schedule) do
          {:ok, _cron_expression} ->
            changeset

          {:error, error} ->
            add_error(changeset, :schedule, error.message)
        end
    end
  end
end
