defmodule HackScraperWeb.HackathonHTML do
  use HackScraperWeb, :html

  embed_templates "hackathon_html/*"

  @doc """
  Renders a hackathon form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def hackathon_form(assigns)
end
