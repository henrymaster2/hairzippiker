defmodule HairZippikerWeb.AdminDashboardLive do
  use HairZippikerWeb, :live_view

  import Ecto.Query, warn: false
  alias HairZippiker.Repo
  alias HairZippiker.Accounts.User
  alias HairZippiker.Accounts
  alias HairZippiker.Accounts.Scope

  def mount(_params, _session, socket) do
    # Fetching ONLY users with the 'employee' role for the counter
    staff_count =
      User
      |> where([u], u.role == "employee")
      |> Repo.aggregate(:count, :id)

    {:ok,
     socket
     |> assign(page_title: "Admin Dashboard")
     |> assign(dark_mode: true)
     |> assign(mobile_menu_open: false)
     |> assign(staff_count: staff_count)}
  end

  # This fixes the "can't be blank" error for password_confirmation
  def handle_event("hire_staff", params, socket) do
    preset_password = "Welcome@2026!"

    # Merge the preset password into the parameters for both fields
    staff_params =
      params
      |> Map.put("password", preset_password)
      |> Map.put("password_confirmation", preset_password)
      |> Map.put("role", "employee")

    case Accounts.register_user(staff_params) do
      {:ok, _user} ->
        # Refresh the count after successful hire
        new_count = User |> where([u], u.role == "employee") |> Repo.aggregate(:count, :id)

        {:noreply,
         socket
         |> put_flash(:info, "Staff hired successfully!")
         |> assign(staff_count: new_count)}

      {:error, %Ecto.Changeset{} = changeset} ->
        # Log the error for debugging
        IO.inspect(changeset.errors, label: "Hiring Failed")
        {:noreply, put_flash(socket, :error, "Could not hire staff. Check if email is unique.")}
    end
  end

  def handle_event("toggle-theme", _params, socket) do
    {:noreply, assign(socket, dark_mode: !socket.assigns.dark_mode)}
  end

  def handle_event("toggle-mobile-menu", _params, socket) do
    {:noreply, assign(socket, mobile_menu_open: !socket.assigns.mobile_menu_open)}
  end

  def handle_event("validate_profile", %{"user" => params}, socket) do
    profile_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_profile(params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, profile_form: profile_form)}
  end

  def handle_event("update_profile", %{"user" => params}, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.update_user(user, params) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(user: updated_user)
         |> assign(current_scope: Scope.for_user(updated_user))
         |> assign_profile_forms(updated_user)
         |> put_flash(:info, "Profile updated successfully!")}

      {:error, changeset} ->
        {:noreply, assign(socket, profile_form: to_form(changeset))}
    end
  end

  def handle_event("validate_password", %{"user" => params}, socket) do
    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", %{"user" => params}, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.update_user_password(user, params) do
      {:ok, {updated_user, _expired_tokens}} ->
        {:noreply,
         socket
         |> assign(user: updated_user)
         |> assign(current_scope: Scope.for_user(updated_user))
         |> assign_profile_forms(updated_user)
         |> put_flash(:info, "Password updated successfully.")}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end

  def handle_params(_params, _uri, %{assigns: %{live_action: :profile}} = socket) do
    {:noreply, assign_profile(socket)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, page_title: "Admin Dashboard")}
  end

  defp assign_profile(socket) do
    user = socket.assigns.current_scope.user

    socket
    |> assign(page_title: "Admin Profile")
    |> assign(user: user)
    |> assign_profile_forms(user)
  end

  defp assign_profile_forms(socket, user) do
    socket
    |> assign(
      :profile_form,
      to_form(Accounts.change_user_profile(user, %{}, validate_unique: false))
    )
    |> assign(
      :password_form,
      to_form(Accounts.change_user_password(user, %{}, hash_password: false))
    )
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} shell={false}>
      <div class={if @dark_mode, do: "theme-dark", else: "theme-light"}>
        <div class="layout">
          <div class="mobile-bar">
            <div class="brand">Hair<span>Zippiker</span></div>
            <button phx-click="toggle-mobile-menu" class="icon-btn">☰</button>
          </div>

          <aside class={["sidebar", if(@mobile_menu_open, do: "open", else: "")]}>
            <div class="sidebar-top">
              <div class="brand-lg">Hair<span>Zippiker</span></div>
              <p class="muted">Admin Console</p>
            </div>

            <nav class="nav">
              <div class="nav-label">Navigation</div>
              <.nav_link href={~p"/admin/dashboard"} active={@live_action == :index}>
                Overview
              </.nav_link>
              <.nav_link href={~p"/admin/staff"} active={false}>Staff</.nav_link>
              <.nav_link href={~p"/admin/inventory"} active={false}>Inventory</.nav_link>
              <.nav_link href={~p"/admin/profile"} active={@live_action == :profile}>
                Profile
              </.nav_link>
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

          <%= if @live_action == :profile do %>
            <.profile_page
              user={@current_scope.user}
              profile_form={@profile_form}
              password_form={@password_form}
            />
          <% else %>
            <.dashboard_page staff_count={@staff_count} />
          <% end %>
        </div>

        <style>
          .theme-dark {
            --bg: #05060a;
            --text: #f8fafc;
            --muted: rgba(248,250,252,0.55);
            --glass: rgba(255,255,255,0.06);
            --glass-strong: rgba(255,255,255,0.1);
            --border: rgba(255,255,255,0.08);
            --accent: #3b82f6;
            --accent-soft: rgba(59,130,246,0.25);
          }

          .theme-light {
            --bg: #f4f6fb;
            --text: #0b1220;
            --muted: rgba(11,18,32,0.55);
            --glass: rgba(255,255,255,0.8);
            --glass-strong: rgba(255,255,255,0.95);
            --border: rgba(0,0,0,0.08);
            --accent: #2563eb;
            --accent-soft: rgba(37,99,235,0.15);
          }

          .layout {
            min-height: 100vh;
            display: flex;
            background: radial-gradient(900px 500px at 20% 10%, rgba(59,130,246,0.08), transparent 60%), radial-gradient(900px 500px at 90% 80%, rgba(59,130,246,0.05), transparent 60%), var(--bg);
            color: var(--text);
            font-family: ui-sans-serif, system-ui;
          }

          .mobile-bar { display: none; justify-content: space-between; align-items: center; padding: 16px 20px; border-bottom: 1px solid var(--border); background: var(--glass); backdrop-filter: blur(20px); }
          .icon-btn { border: 1px solid var(--border); background: transparent; color: var(--text); padding: 8px 12px; border-radius: 12px; font-size: 18px; }

          .sidebar {
            width: 300px;
            padding: 26px 22px;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            border-right: 1px solid var(--border);
            background: linear-gradient(180deg, var(--glass-strong), var(--glass));
            backdrop-filter: blur(28px);
            box-shadow: 20px 0 60px rgba(0,0,0,0.25), inset 1px 0 0 rgba(255,255,255,0.05);
          }

          .brand-lg { font-weight: 900; letter-spacing: -0.8px; }
          .brand-lg span { color: var(--accent); text-shadow: 0 0 18px var(--accent-soft); }
          .muted { font-size: 12px; color: var(--muted); }

          .nav { display: flex; flex-direction: column; gap: 8px; margin-top: 12px; }
          .nav-label { font-size: 10px; letter-spacing: 0.2em; text-transform: uppercase; color: var(--muted); margin-bottom: 6px; }

          .nav a {
            padding: 12px 14px;
            border-radius: 14px;
            font-size: 13px;
            font-weight: 600;
            text-decoration: none;
            color: var(--text);
            opacity: 0.7;
            transition: 0.2s ease;
            border: 1px solid transparent;
          }

          .nav a:hover { opacity: 1; background: rgba(59,130,246,0.08); border-color: rgba(59,130,246,0.15); transform: translateX(3px); }
          .nav a.active { background: linear-gradient(135deg, #3b82f6, #2563eb); color: white; box-shadow: 0 12px 30px rgba(59,130,246,0.25); }

          .sidebar-footer { display: flex; flex-direction: column; gap: 14px; margin-top: auto; }
          .toggle { display: flex; justify-content: space-between; align-items: center; background: transparent; border: none; cursor: pointer; }
          .switch { width: 44px; height: 22px; border-radius: 999px; background: rgba(255,255,255,0.1); position: relative; }
          .knob { width: 18px; height: 18px; background: var(--accent); border-radius: 50%; position: absolute; top: 2px; transition: 0.25s; }
          .knob.on { right: 2px; }
          .knob.off { left: 2px; }
          .logout {
            font-size: 14px;
            font-weight: 700;
            color: #ffffff; /* Ensure text is visible on red background */
            text-decoration: none;
            padding: 10px 16px;
            border-radius: 8px;
            background: linear-gradient(135deg, #ef4444, #dc2626);
            box-shadow: 0 4px 12px rgba(239,68,68,0.4);
            transition: transform 0.2s ease, box-shadow 0.2s ease;
            display: inline-block; /* Ensure proper button layout */
            text-align: center; /* Center the text */
          }

          .logout:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 16px rgba(239,68,68,0.6);
          }

          .logout:active {
            transform: translateY(0);
            box-shadow: 0 2px 8px rgba(239,68,68,0.4);
          }

          .main { flex: 1; padding: 42px; }
          .header { display: flex; justify-content: space-between; align-items: flex-end; margin-bottom: 28px; }
          .title { font-size: 44px; font-weight: 900; letter-spacing: -1px; }
          .subtitle { font-size: 13px; color: var(--muted); margin-top: 6px; }

          .grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 18px; }
          .profile-grid { display: grid; grid-template-columns: 0.75fr 1.25fr; gap: 18px; align-items: start; }
          .card {
            padding: 22px;
            border-radius: 22px;
            background: linear-gradient(180deg, var(--glass-strong), var(--glass));
            border: 1px solid var(--border);
            backdrop-filter: blur(18px);
            transition: 0.25s ease;
          }
          .card:hover { transform: translateY(-4px); border-color: rgba(59,130,246,0.25); }
          .label { font-size: 11px; color: var(--muted); text-transform: uppercase; }
          .value { font-size: 38px; font-weight: 900; margin-top: 10px; }
          .highlight { color: var(--accent); }
          .action { display: flex; align-items: center; justify-content: center; font-weight: 700; color: var(--accent); border: 1px dashed rgba(59,130,246,0.3); cursor: pointer; }
          .profile-card { display: flex; flex-direction: column; gap: 16px; }
          .avatar { width: 86px; height: 86px; border-radius: 24px; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #3b82f6, #0f172a); color: white; font-size: 32px; font-weight: 900; box-shadow: 0 18px 40px rgba(59,130,246,0.22); }
          .profile-name { font-size: 26px; font-weight: 900; letter-spacing: 0; }
          .profile-email { color: var(--muted); font-size: 13px; overflow-wrap: anywhere; }
          .form-stack { display: grid; gap: 14px; }
          .form-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; }
          .section-title { font-size: 18px; font-weight: 900; margin-bottom: 4px; }
          .field-help { font-size: 12px; color: var(--muted); margin-bottom: 18px; }
          .admin-input { width: 100%; border-radius: 14px; border: 1px solid var(--border); background: rgba(255,255,255,0.06); color: var(--text); padding: 13px 14px; outline: none; transition: 0.2s ease; }
          .admin-input:focus { border-color: rgba(59,130,246,0.65); box-shadow: 0 0 0 4px rgba(59,130,246,0.12); }
          .primary-btn { width: fit-content; border: none; border-radius: 14px; background: linear-gradient(135deg, #3b82f6, #2563eb); color: white; padding: 12px 16px; font-size: 12px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.08em; cursor: pointer; transition: 0.2s ease; }
          .primary-btn:hover { transform: translateY(-1px); box-shadow: 0 14px 28px rgba(59,130,246,0.22); }
          .danger-zone { border-color: rgba(239,68,68,0.2); }

          @media (max-width: 900px) {
            .layout { flex-direction: column; }
            .mobile-bar { display: flex; }
            .sidebar { position: fixed; top: 0; left: 0; height: 100%; transform: translateX(-100%); transition: 0.3s; z-index: 100; }
            .sidebar.open { transform: translateX(0); }
            .grid, .profile-grid, .form-grid { grid-template-columns: 1fr; }
            .main { padding: 20px; }
          }
        </style>
      </div>
    </Layouts.app>
    """
  end

  defp dashboard_page(assigns) do
    ~H"""
    <main class="main">
      <header class="header">
        <div>
          <h1 class="title">Overview</h1>
          <p class="subtitle">Business intelligence dashboard</p>
        </div>
      </header>

      <section class="grid">
        <div class="card">
          <p class="label">Employees</p>
          <h2 class="value">{@staff_count}</h2>
        </div>

        <div class="card">
          <p class="label">Revenue</p>
          <h2 class="value highlight">0.00</h2>
        </div>

        <.link href={~p"/admin/staff"} class="card action">+ Manage Staff</.link>
      </section>
    </main>
    """
  end

  defp profile_page(assigns) do
    ~H"""
    <main class="main">
      <header class="header">
        <div>
          <h1 class="title">Admin Profile</h1>
          <p class="subtitle">Manage your account identity and sign-in credentials</p>
        </div>
      </header>

      <section class="profile-grid">
        <aside class="card profile-card" id="admin-profile-summary">
          <div class="avatar">{initials(@user.full_name || @user.email)}</div>
          <div>
            <p class="label">Signed in as</p>
            <h2 class="profile-name">{@user.full_name || "Admin"}</h2>
            <p class="profile-email">{@user.email}</p>
          </div>
          <div>
            <p class="label">Role</p>
            <p class="profile-email">{String.capitalize(@user.role || "admin")}</p>
          </div>
        </aside>

        <div class="form-stack">
          <section class="card" id="admin-profile-details">
            <h2 class="section-title">Profile Details</h2>
            <p class="field-help">Update the admin name and email address used for this account.</p>

            <.form
              for={@profile_form}
              id="admin-profile-form"
              phx-change="validate_profile"
              phx-submit="update_profile"
              class="form-stack"
            >
              <div class="form-grid">
                <.input
                  field={@profile_form[:full_name]}
                  type="text"
                  label="Full name"
                  required
                  class="admin-input"
                />
                <.input
                  field={@profile_form[:email]}
                  type="email"
                  label="Email"
                  required
                  class="admin-input"
                />
              </div>

              <div class="form-grid">
                <.input
                  field={@profile_form[:phone_number]}
                  type="text"
                  label="Phone number"
                  required
                  class="admin-input"
                />
                <.input
                  field={@profile_form[:nid]}
                  type="text"
                  label="National ID"
                  required
                  class="admin-input"
                />
              </div>

              <button type="submit" class="primary-btn" phx-disable-with="Saving...">
                Save Profile
              </button>
            </.form>
          </section>

          <section class="card danger-zone" id="admin-password-details">
            <h2 class="section-title">Password</h2>
            <p class="field-help">Choose a new password with at least 12 characters.</p>

            <.form
              for={@password_form}
              id="admin-password-form"
              phx-change="validate_password"
              phx-submit="update_password"
              class="form-stack"
            >
              <div class="form-grid">
                <.input
                  field={@password_form[:password]}
                  type="password"
                  label="New password"
                  required
                  class="admin-input"
                />
                <.input
                  field={@password_form[:password_confirmation]}
                  type="password"
                  label="Confirm password"
                  required
                  class="admin-input"
                />
              </div>

              <button type="submit" class="primary-btn" phx-disable-with="Updating...">
                Update Password
              </button>
            </.form>
          </section>
        </div>
      </section>
    </main>
    """
  end

  defp initials(value) when is_binary(value) do
    value
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join("", &String.first/1)
    |> String.upcase()
  end

  defp initials(_value), do: "A"

  defp nav_link(assigns) do
    assigns = assign_new(assigns, :active, fn -> false end)

    ~H"""
    <.link href={@href} class={if @active, do: "active", else: ""}>
      {render_slot(@inner_block)}
    </.link>
    """
  end
end
