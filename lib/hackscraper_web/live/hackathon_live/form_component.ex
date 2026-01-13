defmodule HackScraperWeb.HackathonLive.FormComponent do
  @moduledoc """
  input hackathon or suggestion
  sugg_hint
  date_hint
  """
  use HackScraperWeb, :live_component

  alias HackScraper.Events

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>
      <div :if={assigns[:sugg_hint]} class="mt-2 p-3 bg-blue-50 border border-blue-200 rounded-lg">
        <div class="flex justify-between items-center">
          <div>
            <h3 class="text-sm font-semibold text-blue-900 mb-2">Existing Suggestion</h3>
            <p class="text-sm text-blue-700">
              We've loaded your existing suggestion for this hackathon.
            </p>
          </div>
          <.button
            phx-target={@myself}
            phx-click="delete-suggestion"
            data-confirm="Are you sure you want to delete this suggestion?"
            class="!bg-red-600 hover:!bg-red-800 "
          >
            Delete Suggestion
          </.button>
        </div>
      </div>

      <.simple_form
        for={@form}
        id="hackathon-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:url]} type="text" label="Url" required />
        <.input field={@form[:name]} type="text" label="Name" required />

        <div class="space-y-3">
          <label class="block text-sm font-semibold leading-6 text-zinc-800"> Image </label>

          <.input
            field={@form[:image]}
            type="text"
            label=""
            placeholder="Paste image URL here..."
            class="mb-2"
          />

          <div class="relative">
            <div class="absolute inset-0 flex items-center" aria-hidden="true">
              <div class="w-full border-t border-zinc-300"></div>
            </div>
            <div class="relative flex justify-center text-sm">
              <span class="bg-white px-2 text-zinc-500">or</span>
            </div>
          </div>

          <%!-- Drag & Drop Zone --%>
          <label
            phx-drop-target={@uploads.image.ref}
            class="relative flex flex-col items-center justify-center w-full p-6 transition-all duration-200 border-2 border-dashed rounded-lg cursor-pointer group hover:border-zinc-500 hover:bg-zinc-50 border-zinc-300 bg-white"
          >
            <.live_file_input upload={@uploads.image} class="sr-only" />

            <div :if={Enum.empty?(@uploads.image.entries)} class="text-center pointer-events-none">
              <.icon
                name="hero-cloud-arrow-up"
                class="w-12 h-12 mb-1 text-zinc-400 group-hover:text-zinc-500"
              />
              <div class="flex flex-col items-center text-sm text-zinc-600">
                <span class="font-semibold text-blue-500 group-hover:text-blue-600">
                  Click to upload
                </span>
                <p class="mt-1">or drag and drop</p>
              </div>
            </div>

            <%!-- Preview with Upload Progress --%>
            <div :for={entry <- @uploads.image.entries} class="w-full">
              <.live_img_preview entry={entry} class="max-h-32 mx-auto rounded-lg shadow-sm" />

              <div class="mt-2 space-y-1">
                <%!-- Progress Bar --%>
                <div class="flex items-center gap-3">
                  <div class="flex-1">
                    <div class="w-full bg-zinc-200 rounded-full h-2 overflow-hidden">
                      <div
                        class="bg-blue-600 h-2 transition-all duration-300 rounded-full"
                        style={"width: #{entry.progress}%"}
                      >
                      </div>
                    </div>
                  </div>
                  <span class="text-sm font-medium text-zinc-700">
                    {entry.progress}%
                  </span>
                  <button
                    type="button"
                    phx-target={@myself}
                    phx-click="cancel-upload"
                    phx-value-ref={entry.ref}
                    class="p-1 text-zinc-400 hover:text-red-600 transition-colors"
                    aria-label="Remove image"
                  >
                    <.icon name="hero-x-mark" class="h-5 w-5" />
                  </button>
                </div>

                <p
                  :for={err <- upload_errors(@uploads.image, entry)}
                  class="text-sm text-red-600 flex items-center gap-1"
                >
                  <.icon name="hero-x-circle-mini" class="h-5 w-5" />
                  {error_to_string(err)}
                </p>
              </div>
            </div>
          </label>
        </div>

        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:location]} type="textarea" rows="1" label="Location" />

        <div class="block p-3 text-sm bg-blue-50 rounded border">
          Note: Date and time is in your local timezone.
        </div>

        <div :if={assigns[:date_hint]} class="block p-3 text-sm bg-blue-50 rounded border">
          <span class="font-bold">Date information found:</span> {@date_hint}
        </div>

        <.input field={@form[:start_date]} type="datetime-local" label="Start date" required />
        <.input field={@form[:end_date]} type="datetime-local" label="End date" required />

        <.input
          field={@form[:series_id]}
          type="select"
          label="Series"
          options={series_opts(@form[:series_id])}
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Hackathon</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  defp error_to_string(:too_large), do: "file is too large"
  defp error_to_string(:not_accepted), do: "unacceptable file type"

  defp series_opts(series_id) do
    [[key: "No Series", value: nil, selected: is_nil(series_id)]] ++
      for ser <- HackScraper.Events.list_series() do
        [key: ser.name, value: ser.id, selected: ser.id == series_id]
      end
  end

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> allow_upload(:image, auto_upload: true, accept: ["image/*"])}
  end

  @impl true
  def update(assigns, socket) do
    suggestion = assigns[:suggestion]

    data =
      if suggestion do
        {id, map} = Map.from_struct(suggestion) |> Map.pop(:hackathon_id)
        map = if id, do: Map.put(map, :id, id), else: map
        struct(HackScraper.Events.Hackathon, map)
      else
        assigns[:hackathon]
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(data: data)
     |> assign_new(:form, fn -> to_form(Events.change_hackathon(data)) end)}
  end

  @impl true
  def handle_event("validate", %{"hackathon" => hackathon_params}, socket) do
    changeset = Events.change_hackathon(socket.assigns.data, hackathon_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  def handle_event("delete-suggestion", _, socket) do
    {:ok, _} = Events.delete_suggestion(socket.assigns.suggestion)

    {:noreply,
     socket
     |> assign(:suggestion, nil)
     |> assign(:form, to_form(Events.change_hackathon(socket.assigns.hackathon)))}
  end

  def handle_event("save", %{"hackathon" => hackathon_params}, socket) do
    uploads =
      consume_uploaded_entries(socket, :image, fn %{path: path}, %{uuid: uuid, client_name: client_name} ->
        #{extension, _} = System.cmd("file", ["-b", "--extension", path])
        Path.extname(client_name)
        filename = "#{uuid}.#{Path.extname(client_name)}"
        dest = Path.join(Application.fetch_env!(:hackscraper, :uploads_dir), filename)
        File.rename!(path, dest)
        {:ok, ~p"/uploads/#{filename}"}
      end)

    hackathon_params =
      if image = List.first(uploads),
        do: Map.put(hackathon_params, "image", image),
        else: hackathon_params

    save_hackathon(socket, socket.assigns.action, hackathon_params)
  end

  defp save_hackathon(socket, :edit, hackathon_params) do
    user = socket.assigns.current_user

    if HackScraper.Accounts.can_do?(user, :editor) do
      case Events.update_hackathon(socket.assigns.data, hackathon_params) do
        {:ok, hackathon} ->
          notify_parent({:saved, hackathon})

          {:noreply,
           socket
           |> put_flash(:info, "Hackathon updated successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, form: to_form(changeset))}
      end
    else
      suggestion = socket.assigns.suggestion

      result =
        if suggestion do
          hackathon_params = Map.drop(hackathon_params, ["id", "creator_id", "hackathon_id"])
          Events.update_suggestion(suggestion, hackathon_params)
        else
          hackathon_params
          |> Map.put("creator_id", user.id)
          |> Map.put("hackathon_id", socket.assigns.hackathon.id)
          |> Events.create_suggestion()
        end

      case result do
        {:ok, suggestion} ->
          {:noreply,
           socket
           |> put_flash(:info, "Suggestion submitted successfully")
           |> redirect(to: ~p"/suggestions/#{suggestion}")}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, form: to_form(changeset))}
      end
    end
  end

  defp save_hackathon(socket, :new, hackathon_params) do
    user = socket.assigns.current_user

    if HackScraper.Accounts.can_do?(user, :editor) do
      case Events.create_hackathon(hackathon_params) do
        {:ok, hackathon} ->
          notify_parent({:saved, hackathon})

          {:noreply,
           socket
           |> put_flash(:info, "Hackathon created successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, form: to_form(changeset))}
      end
    else
      hackathon_params
      |> Map.put("creator_id", user.id)
      |> Map.put("hackathon_id", socket.assigns.hackathon.id)
      |> Events.create_suggestion()
      |> case do
        {:ok, suggestion} ->
          {:noreply,
           socket
           |> put_flash(:info, "Suggestion submitted successfully")
           |> redirect(to: ~p"/suggestions/#{suggestion}")}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, form: to_form(changeset))}
      end
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
