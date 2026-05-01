defmodule HairZippiker.Repo.Migrations.CreateBookings do
  use Ecto.Migration

  def change do
    create table(:bookings) do
      add :service_id, references(:services, on_delete: :nilify_all)
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :customer_id, references(:customers, on_delete: :nilify_all)
      add :customer_name, :string, null: false
      add :customer_email, :string
      add :customer_phone, :string
      add :scheduled_date, :date, null: false
      add :scheduled_time, :time, null: false
      add :status, :string, null: false, default: "confirmed"

      timestamps(type: :utc_datetime)
    end

    create index(:bookings, [:user_id])
    create index(:bookings, [:service_id])
    create index(:bookings, [:customer_id])
    create index(:bookings, [:scheduled_date, :scheduled_time])
  end
end
