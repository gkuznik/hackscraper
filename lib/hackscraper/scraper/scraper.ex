defmodule HackScraper.Scrapers.Scraper do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:worker, :url, :paused], sortable: [:worker, :url, :schedule]
  }

  schema "scrapers" do
    field :worker, :string
    field :url, :string
    field :schedule, :string
    field :paused, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(scraper, attrs) do
    scraper
    |> cast(attrs, [:worker, :schedule, :url, :paused])
    |> validate_required([:worker, :schedule])
    |> validate_worker()
    |> validate_schedule()
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
