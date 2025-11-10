defmodule HackScraper.Repo.Migrations.CreateSeries do
  use Ecto.Migration

  def change do
    create table(:series) do
      add :name, :string
      add :description, :text

      timestamps(type: :utc_datetime)
    end
  end
end
