defmodule HairZippiker.Mpesa.StkPush do
  @moduledoc """
  Sends Safaricom Daraja M-Pesa STK Push requests.
  """

  @token_path "/oauth/v1/generate?grant_type=client_credentials"
  @stk_push_path "/mpesa/stkpush/v1/processrequest"

  def initiate(phone_number, amount, account_reference, transaction_desc) do
    with {:ok, config} <- config(),
         {:ok, access_token} <- access_token(config),
         {:ok, payload} <-
           stk_payload(config, phone_number, amount, account_reference, transaction_desc) do
      config.base_url
      |> api_url(@stk_push_path)
      |> Req.post(
        json: payload,
        headers: [
          {"authorization", "Bearer #{access_token}"},
          {"content-type", "application/json"}
        ],
        receive_timeout: 50_000
      )
      |> handle_stk_response()
    end
  end

  defp config do
    load_dotenv()

    config = %{
      consumer_key: System.get_env("MPESA_CONSUMER_KEY"),
      consumer_secret: System.get_env("MPESA_CONSUMER_SECRET"),
      shortcode: System.get_env("MPESA_SHORTCODE"),
      passkey: System.get_env("MPESA_PASSKEY"),
      callback_url: System.get_env("MPESA_CALLBACK_URL"),
      base_url: System.get_env("MPESA_BASE_URL") || "https://sandbox.safaricom.co.ke"
    }

    missing_keys =
      config
      |> Enum.reject(fn {_key, value} -> is_binary(value) and value != "" end)
      |> Enum.map(fn {key, _value} -> key end)

    if missing_keys == [] do
      {:ok, config}
    else
      {:error, :missing_mpesa_config}
    end
  end

  defp load_dotenv do
    if File.exists?(".env") do
      ".env"
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.each(&put_env_from_dotenv_line/1)
    end
  end

  defp put_env_from_dotenv_line(line) do
    line = String.trim(line)

    if String.contains?(line, "=") and not String.starts_with?(line, "#") do
      line = String.replace(line, ~r/^export\s+/, "")
      [key, value] = String.split(line, "=", parts: 2)

      clean_value =
        value
        |> String.trim()
        |> String.replace(~r/^["']|["']$/, "")

      System.put_env(String.trim(key), clean_value)
    end
  end

  defp access_token(config) do
    authorization = Base.encode64("#{config.consumer_key}:#{config.consumer_secret}")

    config.base_url
    |> api_url(@token_path)
    |> Req.get(headers: [{"authorization", "Basic #{authorization}"}], receive_timeout: 50_000)
    |> case do
      {:ok, %{status: 200, body: %{"access_token" => token}}} -> {:ok, token}
      {:ok, %{status: status, body: body}} -> {:error, {:token_request_failed, status, body}}
      {:error, reason} -> {:error, {:token_request_failed, reason}}
    end
  end

  defp stk_payload(config, phone_number, amount, account_reference, transaction_desc) do
    with {:ok, normalized_phone} <- normalize_phone(phone_number),
         {:ok, normalized_amount} <- normalize_amount(amount) do
      timestamp = Calendar.strftime(DateTime.utc_now(), "%Y%m%d%H%M%S")
      password = Base.encode64("#{config.shortcode}#{config.passkey}#{timestamp}")

      {:ok,
       %{
         BusinessShortCode: config.shortcode,
         Password: password,
         Timestamp: timestamp,
         TransactionType: "CustomerPayBillOnline",
         Amount: normalized_amount,
         PartyA: normalized_phone,
         PartyB: config.shortcode,
         PhoneNumber: normalized_phone,
         CallBackURL: callback_url(config.callback_url),
         AccountReference: account_reference,
         TransactionDesc: transaction_desc
       }}
    end
  end

  defp handle_stk_response({:ok, %{status: status, body: body}}) when status in 200..299 do
    {:ok, body}
  end

  defp handle_stk_response({:ok, %{status: status, body: body}}) do
    {:error, {:stk_request_failed, status, body}}
  end

  defp handle_stk_response({:error, reason}), do: {:error, {:stk_request_failed, reason}}

  defp api_url(base_url, path) do
    String.trim_trailing(base_url, "/") <> path
  end

  defp callback_url(url) do
    uri = URI.parse(url)

    if uri.path in [nil, ""] do
      String.trim_trailing(url, "/") <> "/api/mpesa/callback"
    else
      url
    end
  end

  defp normalize_phone(phone) when is_binary(phone) do
    digits = String.replace(phone, ~r/\D/, "")

    cond do
      String.starts_with?(digits, "254") and String.length(digits) == 12 ->
        {:ok, digits}

      String.starts_with?(digits, "0") and String.length(digits) == 10 ->
        {:ok, "254" <> String.slice(digits, 1..-1//1)}

      String.length(digits) == 9 ->
        {:ok, "254" <> digits}

      true ->
        {:error, :invalid_phone_number}
    end
  end

  defp normalize_phone(_phone), do: {:error, :invalid_phone_number}

  defp normalize_amount(amount) when is_integer(amount) and amount > 0, do: {:ok, amount}

  defp normalize_amount(amount) when is_binary(amount) do
    amount
    |> String.replace(",", "")
    |> Integer.parse()
    |> case do
      {integer, ""} when integer > 0 -> {:ok, integer}
      _ -> {:error, :invalid_amount}
    end
  end

  defp normalize_amount(_amount), do: {:error, :invalid_amount}
end
