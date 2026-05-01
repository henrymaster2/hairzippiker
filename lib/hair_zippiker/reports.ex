defmodule HairZippiker.Reports do
  @moduledoc """
  Handles staff performance analytics:
  - daily services
  - monthly services
  - yearly services
  - average rating
  """

  import Ecto.Query
  alias HairZippiker.Repo
  alias HairZippiker.Services.Service

  # =========================
  # DAILY SERVICES
  # =========================
  def daily_services(user_id) do
    from(s in Service,
      where: s.user_id == ^user_id,
      where: fragment("date(?) = current_date", s.inserted_at),
      select: count(s.id)
    )
    |> Repo.one()
    |> normalize_count()
  end

  # =========================
  # MONTHLY SERVICES
  # =========================
  def monthly_services(user_id) do
    from(s in Service,
      where: s.user_id == ^user_id,
      where:
        fragment(
          "date_trunc('month', ?) = date_trunc('month', now())",
          s.inserted_at
        ),
      select: count(s.id)
    )
    |> Repo.one()
    |> normalize_count()
  end

  # =========================
  # YEARLY SERVICES
  # =========================
  def yearly_services(user_id) do
    from(s in Service,
      where: s.user_id == ^user_id,
      where:
        fragment(
          "date_trunc('year', ?) = date_trunc('year', now())",
          s.inserted_at
        ),
      select: count(s.id)
    )
    |> Repo.one()
    |> normalize_count()
  end

  # =========================
  # AVERAGE RATING
  # =========================
  def average_rating(user_id) do
    from(s in Service,
      where: s.user_id == ^user_id,
      select: avg(s.rating)
    )
    |> Repo.one()
    |> normalize_avg()
  end

  # =========================
  # TOP PERFORMERS (OPTIONAL BUT POWERFUL)
  # =========================
  def top_staff(limit \\ 5) do
    from(s in Service,
      join: u in assoc(s, :user),
      group_by: u.id,
      select: %{
        user_id: u.id,
        name: u.full_name,
        total: count(s.id),
        avg_rating: avg(s.rating)
      },
      order_by: [desc: count(s.id)],
      limit: ^limit
    )
    |> Repo.all()
  end

  # =========================
  # HELPERS
  # =========================
  defp normalize_count(nil), do: 0
  defp normalize_count(value), do: value

  defp normalize_avg(nil), do: 0.0
  defp normalize_avg(value), do: Float.round(value, 2)
end
