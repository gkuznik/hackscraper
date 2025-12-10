defmodule HackScraperWeb.SeriesLive.FormComponent do
  use HackScraperWeb, :live_component

  alias HackScraper.Events

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>{@title}</.header>

      <.simple_form
        for={@form}
        id="series-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:url]} type="text" label="Url" />
        <.input field={@form[:image]} type="text" label="Image" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Series</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{series: series} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Events.change_series(series))
     end)}
  end

  @impl true
  def handle_event("validate", %{"series" => series_params}, socket) do
    changeset = Events.change_series(socket.assigns.series, series_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"series" => series_params}, socket) do
    save_series(socket, socket.assigns.action, series_params)
  end

  defp save_series(socket, :edit, series_params) do
    case Events.update_series(socket.assigns.series, series_params) do
      {:ok, series} ->
        notify_parent({:saved, series})

        {:noreply,
         socket
         |> put_flash(:info, "Series updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_series(socket, :new, series_params) do
    case Events.create_series(series_params) do
      {:ok, series} ->
        notify_parent({:saved, series})

        {:noreply,
         socket
         |> put_flash(:info, "Series created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
