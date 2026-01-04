defmodule HackScraper.Events.Hackathon do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    sortable: [:name, :start_date, :end_date],
    filterable: [:text],
    adapter_opts: [
      compound_fields: [text: [:name, :url, :description, :location]]
    ]
  }

  schema "hackathons" do
    field :name, :string
    field :description, :string
    field :location, :string
    field :image, :string
    field :url, :string
    field :timezone, :string, default: "Etc/UTC"
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
      :timezone,
      :start_date,
      :end_date,
      :series_id
    ])
    |> validate_required([:name, :url, :start_date, :end_date, :timezone])
    |> validate_change(:timezone, fn :timezone, timezone ->
      if Enum.member?(TimeZoneInfo.time_zones(links: :ignore), timezone),
        do: [],
        else: [timezone: "is not a valid timezone"]
    end)
    |> convert_dates_to_utc()
    |> validate_positive_duration()
    |> unsafe_validate_unique([:url, :start_date], HackScraper.Repo)
    |> unique_constraint([:url, :start_date])
  end

  defp validate_positive_duration(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if start_date && end_date && DateTime.compare(end_date, start_date) != :gt do
      add_error(changeset, :end_date, "must be after start date")
    else
      changeset
    end
  end

  defp convert_dates_to_utc(%{valid?: false} = changeset), do: changeset

  defp convert_dates_to_utc(changeset) do
    timezone = get_field(changeset, :timezone)

    changeset
    |> convert_field_to_utc(:start_date, timezone)
    |> convert_field_to_utc(:end_date, timezone)
  end

  defp convert_field_to_utc(changeset, field, timezone) do
    with datetime <- get_field(changeset, field),
         {:ok, converted} <- convert_to_utc(datetime, timezone) do
      put_change(changeset, field, converted)
    else
      {:error, message} -> add_error(changeset, field, message)
    end
  end

  defp convert_to_utc(datetime, timezone) do
    with naive <- DateTime.to_naive(datetime),
         {:ok, dt} <- DateTime.from_naive(naive, timezone) do
      {:ok, DateTime.shift_zone!(dt, "Etc/UTC")}
    else
      {:ambiguous, _, _} -> {:error, "this point in time is ambiguous in the given timezone"}
      {:gap, _, _} -> {:error, "this point in time does not exist in the given timezone"}
      {:error, reason} -> {:error, "could not convert time: #{reason}"}
    end
  end
end
