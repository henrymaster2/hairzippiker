defmodule HairZippiker.Bookings.Booking do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bookings" do
    field :customer_name, :string
    field :customer_email, :string
    field :customer_phone, :string
    field :scheduled_date, :date
    field :scheduled_time, :time
    field :status, :string, default: "confirmed"

    belongs_to :service, HairZippiker.Services.Service
    belongs_to :user, HairZippiker.Accounts.User
    belongs_to :customer, HairZippiker.Accounts.Customer

    timestamps(type: :utc_datetime)
  end

  def changeset(booking, attrs) do
    booking
    |> cast(attrs, [
      :service_id,
      :user_id,
      :customer_id,
      :customer_name,
      :customer_email,
      :customer_phone,
      :scheduled_date,
      :scheduled_time,
      :status
    ])
    |> validate_required([
      :service_id,
      :user_id,
      :customer_name,
      :scheduled_date,
      :scheduled_time,
      :status
    ])
    |> validate_inclusion(:status, ["confirmed", "pending", "cancelled", "finished"])
    |> foreign_key_constraint(:service_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:customer_id)
  end
end
