defmodule HairZippiker.Bookings do
  @moduledoc """
  Booking functions for customer haircut reservations.
  """

  import Ecto.Query, warn: false

  alias HairZippiker.Accounts.{Customer, Scope}
  alias HairZippiker.Bookings.Booking
  alias HairZippiker.Repo
  alias HairZippiker.Services

  def list_employee_bookings(%Scope{user: user}) do
    list_employee_bookings(user)
  end

  def list_employee_bookings(%{id: user_id}) do
    from(b in Booking,
      where: b.user_id == ^user_id,
      order_by: [asc: b.scheduled_date, asc: b.scheduled_time],
      preload: [:customer, :service]
    )
    |> Repo.all()
  end

  def create_booking(%Customer{} = customer, attrs) do
    do_create_booking(attrs, customer)
  end

  def create_booking(attrs), do: do_create_booking(attrs, nil)

  defp do_create_booking(attrs, customer) do
    attrs = normalize_keys(attrs)

    with {:ok, service_id} <- parse_id(Map.get(attrs, "style_id")),
         service when not is_nil(service) <- Services.get_public_haircut(service_id) do
      booking_attrs =
        attrs
        |> Map.put("service_id", service.id)
        |> Map.put("user_id", service.user_id)
        |> move_booking_slot_fields()
        |> put_customer_details(customer)
        |> Map.put_new("status", "confirmed")

      %Booking{}
      |> Booking.changeset(booking_attrs)
      |> Repo.insert()
    else
      _ -> {:error, :invalid_style}
    end
  end

  defp put_customer_details(attrs, %Customer{} = customer) do
    attrs
    |> Map.put("customer_id", customer.id)
    |> Map.put("customer_name", customer.name)
    |> Map.put("customer_email", customer.email)
    |> Map.put("customer_phone", customer.phone)
  end

  defp put_customer_details(attrs, _customer) do
    Map.put_new(attrs, "customer_name", "Walk-in customer")
  end

  defp move_booking_slot_fields(attrs) do
    attrs
    |> Map.put("scheduled_date", Map.get(attrs, "date"))
    |> Map.put("scheduled_time", Map.get(attrs, "time"))
  end

  defp parse_id(id) when is_integer(id), do: {:ok, id}

  defp parse_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {integer, ""} -> {:ok, integer}
      _ -> :error
    end
  end

  defp parse_id(_id), do: :error

  defp normalize_keys(attrs) do
    Enum.into(attrs, %{}, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end
end
