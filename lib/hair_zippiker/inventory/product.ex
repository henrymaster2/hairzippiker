defmodule HairZippiker.Inventory.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string
    field :type, :string
    field :selling_price, :float
    field :buying_price, :float
    field :stock, :integer, default: 0
    field :image_url, :string

    timestamps()
  end

  @doc false
  def changeset(product, attrs) do
    product
    # Added :type and :image_url to the cast and validation lists
    |> cast(attrs, [:name, :type, :selling_price, :buying_price, :stock, :image_url])
    |> validate_required([:name, :type, :selling_price, :buying_price, :stock])
  end
end
