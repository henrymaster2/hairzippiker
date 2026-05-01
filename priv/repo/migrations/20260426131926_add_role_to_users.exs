defmodule HairZippiker.Repo.Migrations.AddRoleToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :role, :string, default: "employee", null: false
      add :status, :string, default: "active", null: false
    end
  end
end
