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
        <.input field={@form[:name]} type="text" label="Name" required />
        <.input field={@form[:url]} type="text" label="Url" />
        <.input field={@form[:description]} type="textarea" label="Description" required />
        <.image_upload_input field={@form[:image]} upload={@uploads.image} target={@myself} />
        <:actions>
          <.button phx-disable-with="Saving...">Save Series</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> allow_upload(:image, auto_upload: true, accept: ["image/*"])}
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

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  def handle_event("save", %{"series" => series_params}, socket) do
    uploads =
      consume_uploaded_entries(socket, :image, fn %{path: path},
                                                  %{uuid: uuid, client_name: client_name} ->
        filename = "#{uuid}.#{Path.extname(client_name)}"
        dest = Path.join(Application.fetch_env!(:hackscraper, :uploads_dir), filename)
        File.rename!(path, dest)
        {:ok, ~p"/uploads/#{filename}"}
      end)

    series_params =
      if image = List.first(uploads),
        do: Map.put(series_params, "image", image),
        else: series_params

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
