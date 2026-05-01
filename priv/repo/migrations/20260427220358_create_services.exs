defmodule HairZippiker.Repo.Migrations.CreateServices do
  use Ecto.Migration

  def change do
    create table(:services) do
      add :user_id, references(:users, on_delete: :delete_all), null: false

      add :customer_name, :string
      add :rating, :integer
      add :service_type, :string

      timestamps()
    end

    create index(:services, [:user_id])
    create index(:services, [:inserted_at])
  end
end
