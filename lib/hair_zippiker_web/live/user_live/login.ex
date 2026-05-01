defmodule HairZippikerWeb.UserLive.Login do
  use HairZippikerWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} shell={false}>
      <main class="relative min-h-screen w-full overflow-y-auto bg-black font-sans text-white flex items-center justify-center">
        <div class="absolute inset-0 bg-gradient-to-b from-slate-900 via-black to-black opacity-90 z-0">
        </div>

        <div class="relative z-10 w-full max-w-lg px-6">
          <div class="bg-white/5 backdrop-blur-2xl border border-white/10 p-8 md:p-12 rounded-[40px] shadow-2xl shadow-blue-500/5">
            <div class="text-center mb-10">
              <h2 class="text-3xl md:text-4xl font-black uppercase italic tracking-tighter text-white">
                Welcome <span class="text-blue-500">Back</span>
              </h2>
              <p class="text-white/40 text-[10px] uppercase tracking-[0.3em] mt-2">
                Log in to your profile
              </p>
            </div>

            <%!-- action={~p"/users/log-in"} is required for Phoenix Auth --%>
            <.form
              for={@form}
              id="login_form"
              action={~p"/users/log-in"}
              phx-update="ignore"
              class="space-y-6"
            >
              <div>
                <label class="text-[10px] font-black uppercase tracking-widest text-white/40 ml-2 mb-2 block">
                  Email Address
                </label>
                <.input
                  field={@form[:email]}
                  type="email"
                  placeholder="name@example.com"
                  required
                  class="w-full bg-white/5 border border-white/10 p-5 rounded-2xl text-white outline-none focus:border-blue-500 transition-all placeholder:text-white/10"
                />
              </div>

              <div class="relative">
                <div class="flex justify-between items-center ml-2 mb-2">
                  <label class="text-[10px] font-black uppercase tracking-widest text-white/40 block">
                    Password
                  </label>
                  <.link
                    href={~p"/users/reset-password"}
                    class="text-[9px] font-black uppercase text-blue-500/60 hover:text-blue-400"
                  >
                    Forgot?
                  </.link>
                </div>

                <div class="relative">
                  <.input
                    field={@form[:password]}
                    type={if @show_password, do: "text", else: "password"}
                    placeholder="••••••••"
                    required
                    class="w-full bg-white/5 border border-white/10 p-5 rounded-2xl text-white outline-none focus:border-blue-500 transition-all placeholder:text-white/10"
                  />

                  <button
                    type="button"
                    phx-click="toggle-password"
                    class="absolute right-5 top-1/2 -translate-y-1/2 text-white/20 hover:text-blue-500 transition-colors"
                  >
                    <%= if @show_password do %>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        width="20"
                        height="20"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                      >
                        <path d="M9.88 9.88a3 3 0 1 0 4.24 4.24" /><path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68" /><path d="M6.61 6.61A13.52 13.52 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61" /><line
                          x1="2"
                          x2="22"
                          y1="2"
                          y2="22"
                        />
                      </svg>
                    <% else %>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        width="20"
                        height="20"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                      >
                        <path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z" /><circle
                          cx="12"
                          cy="12"
                          r="3"
                        />
                      </svg>
                    <% end %>
                  </button>
                </div>
              </div>

              <div class="flex items-center px-2">
                <.input
                  field={@form[:remember_me]}
                  type="checkbox"
                  label="Keep me logged in"
                  class="rounded border-white/10 bg-white/5 text-blue-600 focus:ring-0 focus:ring-offset-0"
                />
              </div>

              <button
                type="submit"
                class="w-full py-5 bg-blue-600 text-white font-black uppercase tracking-[0.2em] text-[11px] rounded-2xl shadow-xl shadow-blue-900/40 mt-4 active:scale-95 hover:bg-blue-500 transition-all"
              >
                Log In
              </button>
            </.form>

            <div class="mt-10 text-center border-t border-white/5 pt-8">
              <p class="text-white/20 text-[10px] font-black uppercase tracking-widest">
                Need an account?
                <.link navigate={~p"/users/register"} class="text-blue-500 hover:text-blue-400 ml-1">
                  Register Now
                </.link>
              </p>
            </div>
          </div>

          <div class="text-center mt-8">
            <.link
              href="/"
              class="text-white/20 text-[10px] font-black uppercase tracking-widest hover:text-white transition-all"
            >
              ← Back to Homepage
            </.link>
          </div>
        </div>
      </main>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")

    # We remove temporary_assigns here so the @form is not wiped out
    {:ok,
     socket
     |> assign(form: form)
     |> assign(show_password: false)}
  end

  def handle_event("toggle-password", _params, socket) do
    {:noreply, assign(socket, show_password: !socket.assigns.show_password)}
  end
end
