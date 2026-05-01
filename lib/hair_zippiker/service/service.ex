defmodule HairZippiker.Services.Service do
  use Ecto.Schema
  import Ecto.Changeset

  schema "services" do
    field :name, :string
    field :price, :integer
    field :description, :string
    field :image_url, :string
    field :published, :boolean, default: true

    field :customer_name, :string
    field :rating, :integer
    field :service_type, :string

    belongs_to :user, HairZippiker.Accounts.User

    timestamps()
  end

  def changeset(service, attrs) do
    service
    |> cast(attrs, [
      :customer_name,
      :rating,
      :service_type,
      :name,
      :price,
      :description,
      :image_url,
      :published
    ])
    |> put_user_id(attrs)
    |> validate_required([:user_id])
    |> validate_inclusion(:rating, 1..5)
  end

  def haircut_changeset(service, attrs) do
    service
    |> cast(attrs, [:name, :price, :description, :image_url, :published])
    |> put_user_id(attrs)
    |> validate_required([:user_id, :name, :price])
    |> validate_number(:price, greater_than_or_equal_to: 0)
  end

  defp put_user_id(changeset, %{"user_id" => user_id}),
    do: put_change(changeset, :user_id, user_id)

  defp put_user_id(changeset, %{user_id: user_id}), do: put_change(changeset, :user_id, user_id)
  defp put_user_id(changeset, _attrs), do: changeset
end
