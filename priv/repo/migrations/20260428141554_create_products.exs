defmodule HairZippiker.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string
      add :selling_price, :float
      add :buying_price, :float
      add :stock, :integer, default: 0

      timestamps()
    end
  end
end
