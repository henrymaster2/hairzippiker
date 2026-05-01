defmodule HairZippikerWeb.EmployerDashboardLive do
  use HairZippikerWeb, :live_view

  alias HairZippiker.Accounts
  alias HairZippiker.Bookings
  alias HairZippiker.Cloudinary
  alias HairZippikerWeb.EmployerDashboardComponents
  alias HairZippiker.Services
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    socket =
      socket
      |> assign(page_title: "Staff Dashboard")
      |> assign(user: user)
      |> assign(view: "dashboard")
      |> assign(sidebar_open: false)
      # Controls visibility of password characters
      |> assign(show_password: false)
      |> assign(:password_form, to_form(Accounts.change_user_password(user, %{})))
      |> assign(:style_form, to_form(%{"name" => "", "cost" => "", "note" => ""}))
      |> assign(:show_password_modal, user.must_change_password)
      |> assign(:live_sessions, [])
      |> assign(:appointments, Bookings.list_employee_bookings(socket.assigns.current_scope))
      |> assign(:posted_styles, Services.list_employee_haircuts(socket.assigns.current_scope))
      |> allow_upload(:profile_pic, accept: ~w(.jpg .jpeg .png), max_entries: 1)
      |> allow_upload(:style_pic, accept: ~w(.jpg .jpeg .png), max_entries: 1)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <EmployerDashboardComponents.dashboard
      flash={@flash}
      current_scope={@current_scope}
      sidebar_open={@sidebar_open}
      view={@view}
      user={@user}
      live_sessions={@live_sessions}
      appointments={@appointments}
      posted_styles={@posted_styles}
      password_form={@password_form}
      show_password={@show_password}
      style_form={@style_form}
      uploads={@uploads}
    />
    """
  end

  # --- Handlers ---

  @impl true
  def handle_event("switch_view", %{"view" => view}, socket) do
    # When switching to settings, we refresh the form to clear errors
    socket =
      if view == "settings" do
        assign(
          socket,
          :password_form,
          to_form(Accounts.change_user_password(socket.assigns.user, %{}))
        )
      else
        socket
      end

    {:noreply, assign(socket, view: view, sidebar_open: false)}
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  @impl true
  def handle_event("toggle_password", _, socket) do
    {:noreply, update(socket, :show_password, &(!&1))}
  end

  @impl true
  def handle_event("change_password", %{"user" => params}, socket) do
    user = socket.assigns.user

    case Accounts.update_user_password(user, params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password updated successfully!")
         |> assign(password_form: to_form(Accounts.change_user_password(user, %{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("validate_upload", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("save_profile_pic", _params, socket) do
    user = socket.assigns.user

    photo_urls =
      consume_uploaded_entries(socket, :profile_pic, fn %{path: path}, _entry ->
        case Cloudinary.upload(path, "profile_pics") do
          {:ok, url} -> {:ok, {:ok, url}}
          {:error, reason} -> {:ok, {:error, reason}}
        end
      end)

    case photo_urls do
      [{:ok, url} | _] ->
        {:ok, updated_user} = Accounts.update_user_profile_pic(user, url)

        {:noreply,
         socket |> assign(user: updated_user) |> put_flash(:info, "Profile picture updated!")}

      _ ->
        {:noreply, put_flash(socket, :error, "Could not upload image.")}
    end
  end

  @impl true
  def handle_event("save_style", params, socket) do
    style_params = Map.get(params, "style", params)
    name = Map.get(style_params, "name", "")
    cost = Map.get(style_params, "cost", "")
    note = Map.get(style_params, "note", "")

    case upload_style_image(socket) do
      {:ok, image_url} ->
        attrs = %{
          "name" => name,
          "price" => parse_integer(cost),
          "description" => note,
          "image_url" => image_url
        }

        save_style(socket, attrs)

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not add that hair style: #{reason}")}
    end
  end

  @impl true
  def handle_event("delete_style", %{"id" => id}, socket) do
    case Services.delete_employee_haircut(socket.assigns.current_scope, id) do
      {:ok, _style} ->
        {:noreply,
         socket
         |> assign(:posted_styles, Services.list_employee_haircuts(socket.assigns.current_scope))
         |> put_flash(:info, "Hair style deleted.")}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "That hair style could not be found.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not delete that hair style.")}
    end
  end

  # --- Helpers ---

  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} -> integer
      _other -> 0
    end
  end

  defp parse_integer(value) when is_integer(value), do: value
  defp parse_integer(_value), do: 0

  defp save_style(socket, attrs) do
    case Services.create_haircut(socket.assigns.current_scope, attrs) do
      {:ok, _style} ->
        {:noreply,
         socket
         |> assign(posted_styles: Services.list_employee_haircuts(socket.assigns.current_scope))
         |> assign(style_form: to_form(%{"name" => "", "cost" => "", "note" => ""}))
         |> assign(view: "posted_styles")
         |> put_flash(:info, "Hair style added successfully!")}

      {:error, changeset} ->
        error_message = style_changeset_error(changeset)
        Logger.error("Style post failed: #{inspect(changeset.errors)}")

        {:noreply,
         socket
         |> assign(style_form: to_form(changeset))
         |> put_flash(:error, "Could not add that hair style: #{error_message}")}
    end
  end

  defp upload_style_image(socket) do
    if Enum.any?(socket.assigns.uploads.style_pic.entries, &(!&1.done?)) do
      {:error, "wait for the photo preview to finish loading, then try again"}
    else
      consume_style_image(socket)
    end
  end

  defp consume_style_image(socket) do
    upload_results =
      try do
        consume_uploaded_entries(socket, :style_pic, fn %{path: path}, _entry ->
          case Cloudinary.upload(path, "styles") do
            {:ok, url} -> {:ok, {:ok, url}}
            {:error, reason} -> {:ok, {:error, reason}}
          end
        end)
      catch
        :exit, reason ->
          Logger.error("Style image upload consume failed: #{inspect(reason)}")
          [{:error, "image upload expired before save"}]
      end

    case upload_results do
      [{:ok, url} | _] ->
        {:ok, url}

      [{:error, reason} | _] ->
        {:error, "image upload failed: #{reason}"}

      [] ->
        {:error, "choose a photo before adding the hair style"}
    end
  end

  defp style_changeset_error(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, messages} -> "#{field} #{Enum.join(messages, ", ")}" end)
    |> Enum.join("; ")
    |> case do
      "" -> "check your inputs"
      message -> message
    end
  end
end
