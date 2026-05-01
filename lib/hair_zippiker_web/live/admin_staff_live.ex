defmodule HairZippikerWeb.AdminStaffLive do
  use HairZippikerWeb, :live_view

  alias HairZippiker.Accounts

  @default_password "Welcome@2026!"

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Staff Management")
     |> assign(show_form: false)
     |> assign(dark_mode: true)
     |> assign(mobile_menu_open: false)
     |> assign(default_password: @default_password)
     |> assign(new_staff: %{full_name: "", email: ""})
     |> load_staff()}
  end

  defp load_staff(socket) do
    staff =
      Accounts.list_staff()
      |> Enum.map(fn u ->
        %{
          id: u.id,
          name: u.full_name,
          email: u.email,
          status: u.status || "active"
        }
      end)

    assign(socket, staff: staff)
  end

  # =========================
  # UI EVENTS
  # =========================

  def handle_event("toggle_form", _params, socket) do
    {:noreply, assign(socket, show_form: !socket.assigns.show_form)}
  end

  def handle_event("toggle-theme", _params, socket) do
    {:noreply, assign(socket, dark_mode: !socket.assigns.dark_mode)}
  end

  def handle_event("toggle-mobile-menu", _params, socket) do
    {:noreply, assign(socket, mobile_menu_open: !socket.assigns.mobile_menu_open)}
  end

  # =========================
  # CREATE STAFF (Fixed Validation)
  # =========================

  def handle_event("hire_staff", %{"full_name" => name, "email" => email}, socket) do
    # FIX: Added password_confirmation to match the schema requirements
    attrs = %{
      "full_name" => name,
      "email" => email,
      "phone_number" => "0000000000",
      "nid" => "000000",
      "role" => "employee",
      "status" => "active",
      "password" => @default_password,
      "password_confirmation" => @default_password
    }

    case Accounts.register_user(attrs) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Employee account created successfully!")
         |> assign(show_form: false)
         |> load_staff()}

      {:error, changeset} ->
        # This will now help us see if there are other hidden errors (like email taken)
        IO.inspect(changeset.errors, label: "VALIDATION FAILED")

        error_msg =
          case changeset.errors[:email] do
            {msg, _} -> "Email #{msg}"
            _ -> "Registration failed. Check your data."
          end

        {:noreply, put_flash(socket, :error, error_msg)}
    end
  end

  # =========================
  # STAFF ACTIONS
  # =========================

  def handle_event("suspend", %{"id" => id}, socket) do
    Accounts.update_user_status(id, "suspended")
    {:noreply, load_staff(socket)}
  end

  def handle_event("fire", %{"id" => id}, socket) do
    Accounts.update_user_status(id, "fired")
    {:noreply, load_staff(socket)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} shell={false}>
      <div class={if @dark_mode, do: "theme-dark", else: "theme-light"}>
        <div class="layout">
          <div class="mobile-bar">
            <div class="brand">Hair<span>Zippiker</span></div>
            <button phx-click="toggle-mobile-menu" class="icon-btn">Menu</button>
          </div>

          <aside class={["sidebar", if(@mobile_menu_open, do: "open", else: "")]}>
            <div class="sidebar-top">
              <div class="brand-lg">Hair<span>Zippiker</span></div>
              <p class="muted">Admin Console</p>
            </div>

            <nav class="nav">
              <div class="nav-label">Navigation</div>
              <.nav_link href={~p"/admin/dashboard"} active={false}>Overview</.nav_link>
              <.nav_link href={~p"/admin/staff"} active={true}>Staff</.nav_link>
              <.nav_link href={~p"/admin/inventory"} active={false}>Inventory</.nav_link>
              <.nav_link href={~p"/admin/profile"} active={false}>Profile</.nav_link>
            </nav>

            <div class="sidebar-footer">
              <button phx-click="toggle-theme" class="toggle">
                <span class="muted">{if @dark_mode, do: "Light Mode", else: "Dark Mode"}</span>
                <div class="switch">
                  <div class={["knob", if(@dark_mode, do: "on", else: "off")]}></div>
                </div>
              </button>
              <.link href={~p"/users/log-out"} method="delete" class="logout">Sign out</.link>
            </div>
          </aside>

          <main class="main">
            <header class="header">
              <div>
                <h1 class="title">Staff Management</h1>
                <p class="subtitle">Create and manage employee accounts</p>
              </div>

              <button phx-click="toggle_form" class="primary-btn" id="staff-form-toggle">
                {if @show_form, do: "Close Form", else: "Hire Staff"}
              </button>
            </header>

            <section class="stats-grid">
              <div class="card">
                <p class="label">Employees</p>
                <h2 class="value">{length(@staff)}</h2>
              </div>
              <div class="card">
                <p class="label">Default Password</p>
                <h2 class="value small">{@default_password}</h2>
              </div>
            </section>

            <%= if @show_form do %>
              <form phx-submit="hire_staff" class="card form-stack" id="staff-hire-form">
                <div>
                  <h2 class="section-title">New Employee Details</h2>
                  <p class="field-help">
                    Employee accounts are created with the universal starter password.
                  </p>
                </div>

                <div class="form-grid">
                  <label>
                    <span class="label">Full name</span>
                    <input
                      name="full_name"
                      placeholder="e.g. Henry Bundi"
                      required
                      class="admin-input"
                    />
                  </label>

                  <label>
                    <span class="label">Email address</span>
                    <input
                      name="email"
                      type="email"
                      placeholder="employee@hairzippiker.com"
                      required
                      class="admin-input"
                    />
                  </label>
                </div>

                <button type="submit" class="primary-btn">Generate Account</button>
              </form>
            <% end %>

            <section class="staff-list" id="staff-list">
              <%= for s <- @staff do %>
                <article class="card staff-row" id={"staff-#{s.id}"}>
                  <div class="staff-identity">
                    <div class="avatar">{initial(s.name)}</div>
                    <div>
                      <h3 class="staff-name">{s.name}</h3>
                      <p class="staff-email">{s.email}</p>
                      <span class={["status-pill", status_class(s.status)]}>{s.status}</span>
                    </div>
                  </div>

                  <div class="actions">
                    <button phx-click="suspend" phx-value-id={s.id} class="secondary-btn">
                      Suspend
                    </button>
                    <button phx-click="fire" phx-value-id={s.id} class="danger-btn">
                      Terminate
                    </button>
                  </div>
                </article>
              <% end %>
            </section>
          </main>
        </div>

        <.admin_styles />
      </div>
    </Layouts.app>
    """
  end

  defp admin_styles(assigns) do
    ~H"""
    <style>
      .theme-dark { --bg: #05060a; --text: #f8fafc; --muted: rgba(248,250,252,0.55); --glass: rgba(255,255,255,0.06); --glass-strong: rgba(255,255,255,0.1); --border: rgba(255,255,255,0.08); --accent: #3b82f6; --accent-soft: rgba(59,130,246,0.25); }
      .theme-light { --bg: #f4f6fb; --text: #0b1220; --muted: rgba(11,18,32,0.55); --glass: rgba(255,255,255,0.8); --glass-strong: rgba(255,255,255,0.95); --border: rgba(0,0,0,0.08); --accent: #2563eb; --accent-soft: rgba(37,99,235,0.15); }
      .layout { min-height: 100vh; display: flex; background: radial-gradient(900px 500px at 20% 10%, rgba(59,130,246,0.08), transparent 60%), radial-gradient(900px 500px at 90% 80%, rgba(59,130,246,0.05), transparent 60%), var(--bg); color: var(--text); font-family: ui-sans-serif, system-ui; }
      .mobile-bar { display: none; justify-content: space-between; align-items: center; padding: 16px 20px; border-bottom: 1px solid var(--border); background: var(--glass); backdrop-filter: blur(20px); }
      .icon-btn { border: 1px solid var(--border); background: transparent; color: var(--text); padding: 8px 12px; border-radius: 12px; font-size: 13px; font-weight: 800; }
      .brand, .brand-lg { font-weight: 900; letter-spacing: 0; }
      .brand span, .brand-lg span { color: var(--accent); text-shadow: 0 0 18px var(--accent-soft); }
      .sidebar { width: 300px; padding: 26px 22px; display: flex; flex-direction: column; justify-content: space-between; border-right: 1px solid var(--border); background: linear-gradient(180deg, var(--glass-strong), var(--glass)); backdrop-filter: blur(28px); box-shadow: 20px 0 60px rgba(0,0,0,0.25), inset 1px 0 0 rgba(255,255,255,0.05); }
      .muted { font-size: 12px; color: var(--muted); }
      .nav { display: flex; flex-direction: column; gap: 8px; margin-top: 12px; }
      .nav-label { font-size: 10px; letter-spacing: 0.2em; text-transform: uppercase; color: var(--muted); margin-bottom: 6px; }
      .nav a { padding: 12px 14px; border-radius: 14px; font-size: 13px; font-weight: 600; text-decoration: none; color: var(--text); opacity: 0.7; transition: 0.2s ease; border: 1px solid transparent; }
      .nav a:hover { opacity: 1; background: rgba(59,130,246,0.08); border-color: rgba(59,130,246,0.15); transform: translateX(3px); }
      .nav a.active { background: linear-gradient(135deg, #3b82f6, #2563eb); color: white; box-shadow: 0 12px 30px rgba(59,130,246,0.25); }
      .sidebar-footer { display: flex; flex-direction: column; gap: 14px; margin-top: auto; }
      .toggle { display: flex; justify-content: space-between; align-items: center; background: transparent; border: none; cursor: pointer; }
      .switch { width: 44px; height: 22px; border-radius: 999px; background: rgba(255,255,255,0.1); position: relative; }
      .knob { width: 18px; height: 18px; background: var(--accent); border-radius: 50%; position: absolute; top: 2px; transition: 0.25s; }
      .knob.on { right: 2px; } .knob.off { left: 2px; }
      .logout { font-size: 12px; color: #ef4444; text-decoration: none; }
      .main { flex: 1; padding: 42px; }
      .header { display: flex; justify-content: space-between; align-items: flex-end; gap: 18px; margin-bottom: 28px; }
      .title { font-size: 44px; font-weight: 900; letter-spacing: 0; }
      .subtitle { font-size: 13px; color: var(--muted); margin-top: 6px; }
      .stats-grid { display: grid; grid-template-columns: 0.7fr 1.3fr; gap: 18px; margin-bottom: 18px; }
      .card { padding: 22px; border-radius: 22px; background: linear-gradient(180deg, var(--glass-strong), var(--glass)); border: 1px solid var(--border); backdrop-filter: blur(18px); transition: 0.25s ease; }
      .card:hover { transform: translateY(-3px); border-color: rgba(59,130,246,0.25); }
      .label { display: block; font-size: 11px; color: var(--muted); text-transform: uppercase; margin-bottom: 8px; }
      .value { font-size: 38px; font-weight: 900; margin-top: 10px; }
      .value.small { font-size: 26px; color: var(--accent); }
      .form-stack { display: grid; gap: 16px; margin-bottom: 18px; }
      .form-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; }
      .section-title { font-size: 18px; font-weight: 900; margin-bottom: 4px; }
      .field-help { font-size: 12px; color: var(--muted); }
      .admin-input { width: 100%; border-radius: 14px; border: 1px solid var(--border); background: rgba(255,255,255,0.06); color: var(--text); padding: 13px 14px; outline: none; transition: 0.2s ease; }
      .admin-input:focus { border-color: rgba(59,130,246,0.65); box-shadow: 0 0 0 4px rgba(59,130,246,0.12); }
      .primary-btn, .secondary-btn, .danger-btn { width: fit-content; border-radius: 14px; padding: 12px 16px; font-size: 12px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.08em; cursor: pointer; transition: 0.2s ease; }
      .primary-btn { border: none; background: linear-gradient(135deg, #3b82f6, #2563eb); color: white; }
      .secondary-btn { border: 1px solid rgba(234,179,8,0.35); color: #eab308; background: transparent; }
      .danger-btn { border: 1px solid rgba(239,68,68,0.35); color: #ef4444; background: transparent; }
      .primary-btn:hover, .secondary-btn:hover, .danger-btn:hover { transform: translateY(-1px); }
      .staff-list { display: grid; gap: 12px; }
      .staff-row { display: flex; justify-content: space-between; gap: 16px; align-items: center; }
      .staff-identity { display: flex; align-items: center; gap: 14px; min-width: 0; }
      .avatar { width: 52px; height: 52px; border-radius: 16px; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #3b82f6, #0f172a); color: white; font-weight: 900; }
      .staff-name { font-size: 17px; font-weight: 900; }
      .staff-email { color: var(--muted); font-size: 13px; overflow-wrap: anywhere; }
      .status-pill { display: inline-flex; margin-top: 8px; border-radius: 999px; padding: 3px 8px; font-size: 10px; font-weight: 900; text-transform: uppercase; }
      .status-active { background: rgba(34,197,94,0.12); color: #22c55e; }
      .status-muted { background: rgba(239,68,68,0.12); color: #ef4444; }
      .actions { display: flex; gap: 8px; flex-wrap: wrap; justify-content: flex-end; }
      @media (max-width: 900px) { .layout { flex-direction: column; } .mobile-bar { display: flex; } .sidebar { position: fixed; top: 0; left: 0; height: 100%; transform: translateX(-100%); transition: 0.3s; z-index: 100; } .sidebar.open { transform: translateX(0); } .main { padding: 20px; } .header, .staff-row { align-items: stretch; flex-direction: column; } .stats-grid, .form-grid { grid-template-columns: 1fr; } .title { font-size: 34px; } }
    </style>
    """
  end

  defp nav_link(assigns) do
    assigns = assign_new(assigns, :active, fn -> false end)

    ~H"""
    <.link href={@href} class={if @active, do: "active", else: ""}>
      {render_slot(@inner_block)}
    </.link>
    """
  end

  defp initial(value) when is_binary(value), do: value |> String.first() |> String.upcase()
  defp initial(_value), do: "S"

  defp status_class("active"), do: "status-active"
  defp status_class(_status), do: "status-muted"
end
