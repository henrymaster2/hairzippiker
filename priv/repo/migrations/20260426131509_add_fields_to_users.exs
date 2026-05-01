defmodule HairZippiker.Repo.Migrations.AddFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :phone_number, :string
      add :nid, :string
    end
  end
end
