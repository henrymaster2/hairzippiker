defmodule HairZippiker.Inventory do
  @moduledoc """
  The Inventory context.
  """
  import Ecto.Query, warn: false
  alias HairZippiker.Repo
  # You'll need to create this Schema
  alias HairZippiker.Inventory.Product

  @doc """
  Returns the list of products.
  """
  def list_products do
    Repo.all(from p in Product, order_by: [desc: p.inserted_at])
  end

  def get_product(id), do: Repo.get(Product, id)

  @doc """
  Creates a product.
  """
  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a product.
  """
  def delete_product(id) do
    product = Repo.get!(Product, id)
    Repo.delete(product)
  end

  @doc """
  Calculates potential profit for an item.
  """
  def calculate_profit(selling, buying) do
    selling - buying
  end
end
