defmodule HairZippikerWeb.UserRegistrationLive do
  use HairZippikerWeb, :live_view

  alias HairZippiker.Accounts
  alias HairZippiker.Accounts.User

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{role: "employee"})

    {:ok,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(:show_password, false)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Register
        <:subtitle>
          Already registered?
          <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
            Log in
          </.link>
        </:subtitle>
      </.header>

      <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
        <.input field={@form[:full_name]} type="text" label="Full name" required />
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:phone_number]} type="tel" label="Phone number" required />
        <.input field={@form[:nid]} type="text" label="National ID" required />
        <.input field={@form[:password]} type="password" label="Password" required />
        <.input
          field={@form[:password_confirmation]}
          type="password"
          label="Confirm password"
          required
        />
        <.button variant="primary" phx-disable-with="Creating account...">Register</.button>
      </.form>
    </Layouts.app>
    """
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{role: "employee"}
      |> Accounts.change_user_registration(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _email} =
          Accounts.deliver_user_confirmation_instructions(user, &url(~p"/users/log-in/#{&1}"))

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{user.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :insert))}
    end
  end
end
