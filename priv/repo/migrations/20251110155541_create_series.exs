defmodule HackScraper.Repo.Migrations.CreateSeries do
  use Ecto.Migration

  def change do
    create table(:series) do
      add :name, :string
      add :url, :string
      add :image, :string
      add :description, :text

      timestamps(type: :utc_datetime)
    end
  end
end
