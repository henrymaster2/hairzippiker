defmodule HairZippiker.Repo.Migrations.AddStatusToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add_if_not_exists :status, :string, default: "active", null: false
    end
  end
end
