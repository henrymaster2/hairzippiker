defmodule HairZippiker.Services do
  @moduledoc """
  Catalog and service history functions.
  """

  import Ecto.Query, warn: false

  alias HairZippiker.Accounts.Scope
  alias HairZippiker.Repo
  alias HairZippiker.Services.Service

  def list_public_haircuts do
    from(s in haircut_query(),
      where: s.published == true,
      order_by: [desc: s.inserted_at],
      preload: [:user]
    )
    |> Repo.all()
  end

  def get_public_haircut(id) do
    from(s in haircut_query(),
      where: s.id == ^id and s.published == true,
      preload: [:user]
    )
    |> Repo.one()
  end

  def list_employee_haircuts(%Scope{user: user}) do
    list_employee_haircuts(user)
  end

  def list_employee_haircuts(%{id: user_id}) do
    from(s in haircut_query(),
      where: s.user_id == ^user_id,
      order_by: [desc: s.inserted_at]
    )
    |> Repo.all()
  end

  def create_haircut(%Scope{user: user}, attrs) do
    create_haircut(user, attrs)
  end

  def create_haircut(%{id: user_id}, attrs) do
    attrs =
      attrs
      |> normalize_keys()
      |> Map.put("user_id", user_id)
      |> Map.put_new("published", true)

    %Service{}
    |> Service.haircut_changeset(attrs)
    |> Repo.insert()
  end

  def delete_employee_haircut(%Scope{user: user}, id) do
    delete_employee_haircut(user, id)
  end

  def delete_employee_haircut(%{id: user_id}, id) do
    case Repo.get_by(Service, id: id, user_id: user_id) do
      nil -> {:error, :not_found}
      service -> Repo.delete(service)
    end
  end

  defp haircut_query do
    from(s in Service, where: not is_nil(s.name))
  end

  defp normalize_keys(attrs) do
    Enum.into(attrs, %{}, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end
end
