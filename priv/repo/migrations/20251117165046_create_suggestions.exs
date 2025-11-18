defmodule HackScraper.Repo.Migrations.CreateSuggestions do
  use Ecto.Migration

  def change do
    create table(:suggestions) do
      add :name, :string
      add :url, :string
      add :image, :string
      add :description, :text
      add :location, :string
      add :date, :string
      add :start_date, :utc_datetime
      add :end_date, :utc_datetime
      add :series_id, references(:series, on_delete: :nilify_all)

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:suggestions, [:series_id])
    create unique_index(:suggestions, :url)
  end
end
