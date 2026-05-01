defmodule HairZippikerWeb.HomeLive do
  use HairZippikerWeb, :live_view
  alias HairZippiker.Accounts

  def mount(_params, session, socket) do
    # Get the token from the session
    token = session["user_token"]

    # ONLY call the database if token is NOT nil and NOT an empty string
    current_user =
      if token && is_binary(token) do
        Accounts.get_user_by_session_token(token)
      else
        nil
      end

    {:ok,
     socket
     |> assign(:current_user, current_user)
     # If no user was found, show the login popup
     |> assign(:show_login, is_nil(current_user))
     |> assign(:form, to_form(%{}))
     |> assign(:past_orders, [])}
  end

  def handle_event("enter_salon", %{"name" => name, "email" => email, "phone" => phone}, socket) do
    # Create guest user credentials
    user_params = %{
      full_name: name,
      email: email,
      phone_number: phone,
      password: "guest_#{:crypto.strong_rand_bytes(10) |> Base.encode64()}"
    }

    case Accounts.register_user(user_params) do
      {:ok, _user} ->
        # Successfully registered, now move to login to set the cookie
        {:noreply, push_navigate(socket, to: ~p"/users/log-in")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Check your details and try again.")}
    end
  end
end
