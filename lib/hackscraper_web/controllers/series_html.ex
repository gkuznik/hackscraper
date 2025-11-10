defmodule HackScraperWeb.SeriesHTML do
  use HackScraperWeb, :html

  embed_templates "series_html/*"

  @doc """
  Renders a series form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def series_form(assigns)
end
