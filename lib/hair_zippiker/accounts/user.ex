defmodule HairZippiker.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :full_name, :string
    field :email, :string

    field :password, :string, virtual: true, redact: true
    field :password_confirmation, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true

    field :phone_number, :string
    field :nid, :string
    field :role, :string, default: "employee"
    field :status, :string, default: "active"
    field :confirmed_at, :utc_datetime
    field :authenticated_at, :utc_datetime
    field :must_change_password, :boolean, default: false
    field :profile_picture_url, :string

    timestamps(type: :utc_datetime)
  end

  # ---------------------------
  # REGISTRATION
  # ---------------------------
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [
      :full_name,
      :email,
      :password,
      :password_confirmation,
      :phone_number,
      :nid,
      :role,
      :status
    ])
    |> validate_required([
      :full_name,
      :email,
      :phone_number,
      :nid
    ])
    |> validate_email(opts)
    |> maybe_validate_password(opts)
  end

  # ---------------------------
  # EMAIL
  # ---------------------------
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> validate_email_changed(attrs)
  end

  defp validate_email_changed(changeset, attrs) do
    email = Map.get(attrs, "email") || Map.get(attrs, :email)

    if email && email == changeset.data.email do
      add_error(changeset, :email, "did not change")
    else
      changeset
    end
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^@\s]+@[^@\s]+\.[^@\s]+$/,
      message: "must have the @ sign and no spaces"
    )
    |> validate_length(:email, max: 160)
    |> maybe_unique_email(opts)
  end

  defp maybe_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:email, HairZippiker.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  # ---------------------------
  # PASSWORD VALIDATION
  # ---------------------------
  defp validate_password(changeset, opts) do
    allow_weak = Keyword.get(opts, :allow_weak_password, false)

    changeset = validate_confirmation(changeset, :password, message: "does not match password")

    changeset =
      if allow_weak do
        validate_length(changeset, :password, min: 4, max: 72)
      else
        validate_length(changeset, :password, min: 12, max: 72)
      end

    maybe_hash_password(changeset, opts)
  end

  defp maybe_validate_password(changeset, opts) do
    if get_change(changeset, :password) do
      validate_password(changeset, opts)
    else
      changeset
    end
  end

  defp maybe_hash_password(changeset, opts) do
    hash? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash? && password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
      |> delete_change(:password_confirmation)
    else
      changeset
    end
  end

  # ---------------------------
  # PASSWORD UPDATE
  # ---------------------------
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password, :password_confirmation])
    |> validate_required([:password])
    |> validate_password(opts)
  end

  # ---------------------------
  # PROFILE UPDATE
  # ---------------------------
  def profile_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:full_name, :email, :phone_number, :nid])
    |> validate_required([:full_name, :email, :phone_number, :nid])
    |> validate_email(opts)
  end

  # ---------------------------
  # STAFF STATUS
  # ---------------------------
  def staff_status_changeset(user, attrs) do
    user
    |> cast(attrs, [:status])
    |> validate_inclusion(:status, ["active", "suspended", "fired"])
  end

  # ---------------------------
  # CONFIRMATION
  # ---------------------------
  def confirm_changeset(user) do
    change(user, confirmed_at: DateTime.utc_now(:second))
  end

  # ---------------------------
  # PASSWORD CHECK
  # ---------------------------
  def valid_password?(%__MODULE__{hashed_password: hashed}, password)
      when is_binary(hashed) and is_binary(password) do
    Bcrypt.verify_pass(password, hashed)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end
end
