defmodule HairZippiker.Repo.Migrations.EnsureServiceHistoryFields do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE services ADD COLUMN IF NOT EXISTS customer_name varchar(255)",
            "ALTER TABLE services DROP COLUMN IF EXISTS customer_name"

    execute "ALTER TABLE services ADD COLUMN IF NOT EXISTS rating integer",
            "ALTER TABLE services DROP COLUMN IF EXISTS rating"

    execute "ALTER TABLE services ADD COLUMN IF NOT EXISTS service_type varchar(255)",
            "ALTER TABLE services DROP COLUMN IF EXISTS service_type"
  end
end
