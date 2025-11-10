defmodule HackScraper.Repo.Migrations.CreateHackathons do
  use Ecto.Migration

  def change do
    create table(:hackathons) do
      add :name, :string
      add :url, :string
      add :image, :string
      add :description, :text
      add :location, :string
      add :start_date, :utc_datetime
      add :end_date, :utc_datetime
      add :series_id, references(:series, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:hackathons, [:series_id])
  end
end
