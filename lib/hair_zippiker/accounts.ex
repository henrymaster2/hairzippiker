defmodule HairZippiker.Accounts do
  @moduledoc """
  Accounts context:
  - Authentication
  - User management
  - Staff management (admin)
  """

  import Ecto.Query, warn: false
  alias HairZippiker.Repo

  alias HairZippiker.Accounts.{User, UserToken, UserNotifier}

  # =========================
  # USER FETCHING
  # =========================

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  def get_user!(id), do: Repo.get!(User, id)

  # =========================
  # REGISTRATION
  # =========================

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs)
  end

  # =========================
  # STAFF MANAGEMENT
  # =========================

  def list_staff do
    from(u in User,
      where: u.role == "employee",
      order_by: [desc: u.inserted_at]
    )
    |> Repo.all()
  end

  def create_staff(attrs \\ %{}) when is_map(attrs) do
    clean_attrs =
      attrs
      |> normalize_keys()
      |> Map.put("password", "Welcome@2026!")
      |> Map.put("role", "employee")
      |> Map.put("status", "active")
      |> Map.put("must_change_password", true)

    %User{}
    |> User.registration_changeset(clean_attrs)
    |> Repo.insert()
  end

  def suspend_staff(id) do
    id
    |> get_user!()
    |> Ecto.Changeset.change(status: "suspended")
    |> Repo.update()
  end

  def fire_staff(id) do
    id
    |> get_user!()
    |> Ecto.Changeset.change(status: "fired")
    |> Repo.update()
  end

  def update_user_status(id, status) when status in ["active", "suspended", "fired"] do
    id
    |> get_user!()
    |> User.staff_status_changeset(%{status: status})
    |> Repo.update()
  end

  # =========================
  # EMAIL UPDATE
  # =========================

  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transaction(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})) do
        Repo.delete_all(
          from t in UserToken, where: t.user_id == ^user.id and t.context == ^context
        )

        user
      else
        _ -> Repo.rollback(:transaction_aborted)
      end
    end)
  end

  # =========================
  # PASSWORD
  # =========================

  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  def change_user_profile(%User{} = user, attrs \\ %{}, opts \\ []) do
    User.profile_changeset(user, attrs, opts)
  end

  def login_user_by_magic_link(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, user_token} <- Repo.one(query) do
      if user.hashed_password && is_nil(user.confirmed_at) do
        raise "magic link log in is not allowed for unconfirmed users with a password set"
      end

      tokens_to_disconnect =
        if user.confirmed_at do
          []
        else
          Repo.all(from t in UserToken, where: t.user_id == ^user.id)
        end

      Repo.transaction(fn ->
        Repo.delete(user_token)

        {:ok, user} =
          user
          |> User.confirm_changeset()
          |> Ecto.Changeset.change(authenticated_at: DateTime.utc_now(:second))
          |> Repo.update()

        {user, tokens_to_disconnect}
      end)
    else
      _ -> {:error, :not_found}
    end
  end

  # =========================
  # SESSION
  # =========================

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def delete_user_session_token(token) do
    Repo.delete_all(from t in UserToken, where: t.token == ^token and t.context == "session")
    :ok
  end

  # =========================
  # EMAIL / LOGIN / MAGIC LINKS
  # =========================

  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
    Repo.insert!(user_token)
    UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
  end

  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")
    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  # NEW: Added to satisfy compiler in LiveView Confirmation
  def get_user_by_magic_link_token(token) do
    case UserToken.verify_email_token_query(token, "login") do
      {:ok, query} ->
        case Repo.one(query) do
          {user, _token} -> user
          nil -> nil
        end

      _ ->
        nil
    end
  end

  # =========================
  # SUDO & STATUS HELPERS
  # =========================

  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: authenticated_at}, minutes)
      when not is_nil(authenticated_at) do
    DateTime.after?(authenticated_at, DateTime.add(DateTime.utc_now(), minutes, :minute))
  end

  def sudo_mode?(%User{}, _minutes), do: false

  # NEW: Added to satisfy UserSessionController
  def disconnect_sessions(_tokens), do: :ok

  # =========================
  # INTERNAL HELPERS
  # =========================

  defp normalize_keys(attrs) do
    attrs
    |> Enum.into(%{}, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} -> {k, v}
    end)
  end

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transaction(fn ->
      case Repo.update(changeset) do
        {:ok, user} ->
          tokens = Repo.all(from t in UserToken, where: t.user_id == ^user.id)
          Repo.delete_all(from t in UserToken, where: t.user_id == ^user.id)
          {user, tokens}

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Set or clear the must_change_password flag on a user.
  """
  def set_must_change_password(%User{} = user, flag) when is_boolean(flag) do
    user
    |> Ecto.Changeset.change(must_change_password: flag)
    |> Repo.update()
  end

  def update_user_profile_pic(%User{} = user, url) when is_binary(url) do
    user
    |> Ecto.Changeset.change(profile_picture_url: url)
    |> Repo.update()
  end
end
