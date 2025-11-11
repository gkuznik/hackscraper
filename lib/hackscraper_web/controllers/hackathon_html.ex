defmodule HackScraperWeb.HackathonHTML do
  use HackScraperWeb, :html

  embed_templates "hackathon_html/*"

  @doc """
  Renders a hackathon form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def hackathon_form(assigns)

  def series_opts(changeset) do
    existing_series = Ecto.Changeset.get_change(changeset, :series)
    existing_id = if existing_series, do: existing_series.data.id, else: nil

    [[key: "No Series", value: nil, selected: is_nil(existing_id)]] ++
      for cat <- HackScraper.Events.list_series() do
        [key: cat.name, value: cat.id, selected: cat.id == existing_id]
      end
  end
end
