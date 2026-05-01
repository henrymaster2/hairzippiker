defmodule HairZippiker.Repo.Migrations.AddCatalogFieldsToServices do
  use Ecto.Migration

  def change do
    alter table(:services) do
      add :name, :string
      add :price, :integer
      add :description, :string
      add :image_url, :string
      add :published, :boolean, default: true, null: false
    end

    create index(:services, [:published])
  end
end
