defmodule HackScraper.Repo.Migrations.CreateSuggestions do
  use Ecto.Migration

  def change do
    create table(:suggestions) do
      add :name, :string
      add :url, :string
      add :image, :string
      add :description, :text
      add :location, :string
      add :date_hint, :string
      add :start_date, :utc_datetime
      add :end_date, :utc_datetime
      add :series_id, references(:series, on_delete: :nilify_all)

      add :creator_id, references(:users, on_delete: :delete_all), null: false
      add :hackathon_id, references(:hackathons, on_delete: :delete_all)

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:suggestions, [:creator_id, :hackathon_id])
    create unique_index(:suggestions, [:creator_id, :url, :start_date], nulls_distinct: false)
  end
end
