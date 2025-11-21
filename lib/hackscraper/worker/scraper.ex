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
    |> validate_name()
    |> validate_schedule()
    |> unique_constraint(:name)
  end

  defp validate_name(changeset) do
    changeset
    |> update_change(:name, &String.downcase/1)
    |> validate_change(:name, fn :name, name ->
      name_prefix = name |> String.split("-", parts: 2) |> List.first()

      if name_prefix in ["devpost", "direct", "dummy"] do
        []
      else
        [name: "must start with one of: devpost, direct, dummy"]
      end
    end)
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
