defmodule HairZippikerWeb.UserForgotPasswordLive do
  use HairZippikerWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>Reset Password</.header>
    </Layouts.app>
    """
  end
end
