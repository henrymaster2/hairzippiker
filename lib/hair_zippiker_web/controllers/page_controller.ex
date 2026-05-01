defmodule HairZippikerWeb.PageController do
  use HairZippikerWeb, :controller

  # We alias your Repo and the new Customer schema we are creating
  alias HairZippiker.Repo
  alias HairZippiker.Accounts.Customer
  alias HairZippiker.Bookings
  alias HairZippiker.Inventory
  alias HairZippiker.Mpesa.StkPush
  alias HairZippiker.Services

  def home(conn, _params) do
    # 1. Check if there is a customer_id in the session
    customer_id = get_session(conn, :customer_id)

    # 2. Fetch the customer if the ID exists, otherwise return nil
    customer =
      if customer_id do
        Repo.get(Customer, customer_id)
      else
        nil
      end

    current_scope = conn.assigns[:current_scope]

    # 3. We pass customer and display name data to the template instead of
    # directly reaching through assigns there.
    render(conn, :home,
      customer: customer,
      current_scope: current_scope,
      visitor_name: visitor_name(customer, current_scope),
      styles: home_styles()
    )
  end

  defp visitor_name(%{name: name}, _current_scope) when is_binary(name) and name != "", do: name

  defp visitor_name(_customer, %{user: %{full_name: full_name}})
       when is_binary(full_name) and full_name != "",
       do: full_name

  defp visitor_name(_customer, %{user: %{email: email}}) when is_binary(email) and email != "",
    do: email

  defp visitor_name(_customer, _current_scope), do: "Guest"

  defp home_styles do
    case Services.list_public_haircuts() do
      [] -> default_styles()
      styles -> Enum.map(styles, &service_to_style/1)
    end
  end

  defp service_to_style(service) do
    %{
      id: service.id,
      name: service.name,
      price: format_price(service.price),
      amount: service.price,
      img: service.image_url || default_style_image(),
      description:
        service.description || "A polished cut built for clean lines and a crisp finish.",
      barber: service.user && service.user.full_name
    }
  end

  defp default_styles do
    [
      %{
        id: "starter-signature-fade",
        name: "Signature Fade",
        price: "1,500",
        amount: 1500,
        img:
          "https://images.unsplash.com/photo-1599351431202-1e0f0137899a?q=80&w=1588&auto=format&fit=crop",
        description:
          "A polished cut built for clean lines, confident movement, and a crisp finish before you leave the chair.",
        barber: nil
      },
      %{
        id: "starter-classic-taper",
        name: "Classic Taper",
        price: "1,200",
        amount: 1200,
        img:
          "https://images.unsplash.com/photo-1621605815841-aa897bd07b5d?q=80&w=1000&auto=format&fit=crop",
        description: "A balanced taper with clean edges and natural shape for everyday polish.",
        barber: nil
      },
      %{
        id: "starter-buzz-cut",
        name: "Buzz Cut",
        price: "800",
        amount: 800,
        img:
          "https://images.unsplash.com/photo-1503910358245-44a77ba73699?q=80&w=1000&auto=format&fit=crop",
        description: "A low-maintenance cut with sharp finishing and confident simplicity.",
        barber: nil
      }
    ]
  end

  defp default_style_image do
    "https://images.unsplash.com/photo-1599351431202-1e0f0137899a?q=80&w=1588&auto=format&fit=crop"
  end

  defp format_price(price) when is_integer(price) do
    price
    |> Integer.to_charlist()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end

  defp format_price(price) when is_binary(price), do: price
  defp format_price(_price), do: "0"

  def book(conn, _params) do
    with {:ok, conn} <- require_payment_phone(conn) do
      render(conn, :book, styles: home_styles())
    end
  end

  def confirm_booking(conn, %{"booking" => booking_params}) do
    customer = current_customer(conn)

    case create_customer_booking(customer, booking_params) do
      {:ok, _booking} ->
        conn
        |> put_flash(:info, "Booking confirmed. Your barber can now see it in the portal.")
        |> redirect(to: ~p"/book")

      {:error, :invalid_style} ->
        conn
        |> put_flash(:error, "Please choose a posted hairstyle before confirming.")
        |> redirect(to: ~p"/book")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "We could not confirm that booking. Please check the date and time.")
        |> redirect(to: ~p"/book")
    end
  end

  def initiate_stk_push(conn, %{"payment" => %{"style_id" => style_id}}) do
    customer = current_customer(conn)

    with {:ok, style} <- payable_style(style_id),
         {:ok, phone} <- payment_phone(conn, customer),
         {:ok, response} <-
           StkPush.initiate(
             phone,
             style.amount,
             "HairZippiker-#{style.id}",
             "Payment for #{style.name}"
           ) do
      json(conn, %{
        ok: true,
        message: "STK push sent. Check your phone to complete payment.",
        response: response
      })
    else
      {:error, :missing_phone_number} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{ok: false, message: "Please enter the salon with a valid phone number first."})

      {:error, :invalid_phone_number} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{ok: false, message: "Your phone number is not valid for M-Pesa STK Push."})

      {:error, :invalid_style} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{ok: false, message: "Choose a posted hairstyle before sending STK Push."})

      {:error, :missing_mpesa_config} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{ok: false, message: "M-Pesa configuration is missing."})

      _error ->
        conn
        |> put_status(:bad_gateway)
        |> json(%{ok: false, message: "Could not send the STK push right now."})
    end
  end

  def initiate_stk_push(conn, %{"payment" => %{"product_id" => product_id} = payment_params}) do
    customer = current_customer(conn)

    with {:ok, product} <- payable_product(product_id),
         {:ok, quantity} <- parse_quantity(payment_params["quantity"], product.stock),
         {:ok, phone} <- payment_phone(conn, customer),
         amount <- round(product.selling_price * quantity),
         {:ok, response} <-
           StkPush.initiate(
             phone,
             amount,
             "HairZippiker-Shop-#{product.id}",
             "Payment for #{quantity} x #{product.name}"
           ) do
      json(conn, %{
        ok: true,
        message: "STK push sent. Check your phone to complete payment.",
        response: response
      })
    else
      {:error, :missing_phone_number} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{ok: false, message: "Please enter the salon with a valid phone number first."})

      {:error, :invalid_phone_number} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{ok: false, message: "Your phone number is not valid for M-Pesa STK Push."})

      {:error, :invalid_quantity} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{ok: false, message: "Choose a valid quantity for this item."})

      {:error, :invalid_product} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{ok: false, message: "Choose an available shop item before sending STK Push."})

      {:error, :missing_mpesa_config} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{ok: false, message: "M-Pesa configuration is missing."})

      _error ->
        conn
        |> put_status(:bad_gateway)
        |> json(%{ok: false, message: "Could not send the STK push right now."})
    end
  end

  def mpesa_callback(conn, params) do
    require Logger
    Logger.info("M-Pesa STK callback: #{inspect(params)}")

    json(conn, %{ok: true})
  end

  defp current_customer(conn) do
    case get_session(conn, :customer_id) do
      nil -> nil
      customer_id -> Repo.get(Customer, customer_id)
    end
  end

  defp payment_phone(_conn, %Customer{phone: phone}) when is_binary(phone) and phone != "" do
    {:ok, phone}
  end

  defp payment_phone(conn, _customer) do
    case conn.assigns[:current_scope] do
      %{user: %{phone_number: phone}} when is_binary(phone) and phone != "" -> {:ok, phone}
      _scope -> {:error, :missing_phone_number}
    end
  end

  defp parse_id(id) when is_integer(id), do: {:ok, id}

  defp parse_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {integer, ""} -> {:ok, integer}
      _ -> {:error, :invalid_style}
    end
  end

  defp parse_id(_id), do: {:error, :invalid_style}

  defp parse_quantity(quantity, stock) when is_binary(quantity) and is_integer(stock) do
    case Integer.parse(quantity) do
      {integer, ""} when integer > 0 and integer <= stock -> {:ok, integer}
      _ -> {:error, :invalid_quantity}
    end
  end

  defp parse_quantity(quantity, stock) when is_integer(quantity) and is_integer(stock) do
    if quantity > 0 and quantity <= stock do
      {:ok, quantity}
    else
      {:error, :invalid_quantity}
    end
  end

  defp parse_quantity(_quantity, _stock), do: {:error, :invalid_quantity}

  defp payable_style(id) do
    case parse_id(id) do
      {:ok, style_id} ->
        case Services.get_public_haircut(style_id) do
          nil -> {:error, :invalid_style}
          service -> {:ok, service_to_style(service)}
        end

      {:error, :invalid_style} ->
        case Enum.find(default_styles(), &(&1.id == id)) do
          nil -> {:error, :invalid_style}
          style -> {:ok, style}
        end
    end
  end

  defp payable_product(id) do
    with {:ok, product_id} <- parse_id(id),
         product when not is_nil(product) <- Inventory.get_product(product_id) do
      {:ok, product}
    else
      _error -> {:error, :invalid_product}
    end
  end

  defp create_customer_booking(%Customer{} = customer, booking_params) do
    Bookings.create_booking(customer, booking_params)
  end

  defp create_customer_booking(_customer, booking_params) do
    Bookings.create_booking(booking_params)
  end

  def shop(conn, _params) do
    with {:ok, conn} <- require_payment_phone(conn) do
      render(conn, :shop, products: Inventory.list_products())
    end
  end

  @doc """
  Handles the 'Gate Pass' form submission.
  It saves the customer to the database and sets the session.
  """
  def enter_salon(conn, %{"customer" => customer_params}) do
    # Create a changeset for the new customer
    changeset = Customer.changeset(%Customer{}, customer_params)

    case Repo.insert(changeset) do
      {:ok, customer} ->
        conn
        |> put_flash(:info, "Welcome to the Salon!")
        # This is the "Gate Pass" key
        |> put_session(:customer_id, customer.id)
        |> redirect(to: ~p"/")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Please provide all details to enter.")
        |> redirect(to: ~p"/")
    end
  end

  @doc """
  Clears the customer session (Logout for customers).
  """
  def exit_salon(conn, _params) do
    conn
    |> delete_session(:customer_id)
    |> redirect(to: ~p"/")
  end

  defp require_payment_phone(conn) do
    case payment_phone(conn, current_customer(conn)) do
      {:ok, _phone} ->
        {:ok, conn}

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Please enter the salon with your phone number before paying.")
        |> redirect(to: ~p"/")
    end
  end
end
