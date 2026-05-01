defmodule HairZippikerWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use HairZippikerWeb, :html

  embed_templates "page_html/*"

  def format_price(amount) when is_binary(amount) and amount != "", do: amount

  def format_price(amount) when is_number(amount) do
    amount
    |> round()
    |> Integer.to_charlist()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end

  def format_price(_amount), do: "0"
end
