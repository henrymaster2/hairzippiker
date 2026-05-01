defmodule HairZippiker.Cloudinary do
  @moduledoc """
  Handles communication with Cloudinary API safely.
  """

  defp config do
    load_dotenv()

    %{
      cloud_name:
        Application.get_env(:hair_zippiker, :cloudinary)[:cloud_name] ||
          System.get_env("CLOUDINARY_CLOUD_NAME"),
      api_key:
        Application.get_env(:hair_zippiker, :cloudinary)[:api_key] ||
          System.get_env("CLOUDINARY_API_KEY"),
      api_secret:
        Application.get_env(:hair_zippiker, :cloudinary)[:api_secret] ||
          System.get_env("CLOUDINARY_API_SECRET")
    }
  end

  @doc """
  Uploads a file to Cloudinary.
  """
  def upload(file_path, folder \\ "inventory") do
    conf = config()
    cloud_name = conf.cloud_name
    api_key = conf.api_key
    api_secret = conf.api_secret

    # Validation check to prevent the Hackney nil error before sending the request
    if is_nil(api_key) or is_nil(cloud_name) or is_nil(api_secret) do
      {:error, "Cloudinary configuration is missing. Ensure .env is loaded."}
    else
      timestamp = DateTime.utc_now() |> DateTime.to_unix()

      # Signature parameters MUST be in alphabetical order: folder then timestamp
      signature_string = "folder=#{folder}&timestamp=#{timestamp}#{api_secret}"

      signature =
        :crypto.hash(:sha, signature_string)
        |> Base.encode16(case: :lower)

      url = "https://api.cloudinary.com/v1_1/#{cloud_name}/image/upload"

      form = [
        file: {File.read!(file_path), filename: Path.basename(file_path)},
        api_key: api_key,
        timestamp: to_string(timestamp),
        signature: signature,
        folder: folder
      ]

      case Req.post(url, form_multipart: form, receive_timeout: 50_000) do
        {:ok, %{status: 200, body: %{"secure_url" => secure_url}}} ->
          {:ok, secure_url}

        {:ok, %{status: status, body: body}} ->
          {:error, "Cloudinary error (Status #{status}): #{inspect(body)}"}

        {:error, reason} ->
          {:error, "Network error: #{inspect(reason)}"}
      end
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
end
