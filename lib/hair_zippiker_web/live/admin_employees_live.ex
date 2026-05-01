defmodule HairZippikerWeb.AdminEmployeesLive do
  use HairZippikerWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, push_navigate(socket, to: ~p"/admin/staff")}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <p>Redirecting...</p>
    </Layouts.app>
    """
  end
end
