defmodule HackScraperWeb.ScraperLive.FormComponent do
  use HackScraperWeb, :live_component

  alias HackScraper.Worker

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage scraper records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="scraper-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:schedule]} type="text" label="Schedule" />
        <.input field={@form[:url]} type="text" label="Url" />
        <.input field={@form[:paused]} type="checkbox" label="Paused" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Scraper</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{scraper: scraper} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Worker.change_scraper(scraper))
     end)}
  end

  @impl true
  def handle_event("validate", %{"scraper" => scraper_params}, socket) do
    changeset = Worker.change_scraper(socket.assigns.scraper, scraper_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"scraper" => scraper_params}, socket) do
    save_scraper(socket, socket.assigns.action, scraper_params)
  end

  defp save_scraper(socket, :edit, scraper_params) do
    case Worker.update_scraper(socket.assigns.scraper, scraper_params) do
      {:ok, scraper} ->
        notify_parent({:saved, scraper})

        {:noreply,
         socket
         |> put_flash(:info, "Scraper updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_scraper(socket, :new, scraper_params) do
    case Worker.create_scraper(scraper_params) do
      {:ok, scraper} ->
        notify_parent({:saved, scraper})

        {:noreply,
         socket
         |> put_flash(:info, "Scraper created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
