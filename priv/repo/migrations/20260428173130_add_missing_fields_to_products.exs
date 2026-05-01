defmodule HairZippiker.Repo.Migrations.AddMissingFieldsToProducts do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :type, :string
      add :image_url, :string
      # If your 'stock' column in DB is currently called 'stock' 
      # but your form uses 'quantity', let's keep it consistent.
      # The error shows your DB already has 'stock'.
    end
  end
end
