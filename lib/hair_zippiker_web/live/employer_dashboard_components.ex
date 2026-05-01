defmodule HairZippikerWeb.EmployerDashboardComponents do
  use HairZippikerWeb, :html

  attr :flash, :map, required: true
  attr :current_scope, :map, required: true
  attr :sidebar_open, :boolean, required: true
  attr :view, :string, required: true
  attr :user, :map, required: true
  attr :live_sessions, :list, required: true
  attr :appointments, :list, required: true
  attr :posted_styles, :list, required: true
  attr :password_form, Phoenix.HTML.Form, required: true
  attr :show_password, :boolean, required: true
  attr :style_form, Phoenix.HTML.Form, required: true
  attr :uploads, :map, required: true

  def dashboard(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} shell={false}>
      <div class="min-h-screen bg-[#050505] text-slate-200 flex font-sans selection:bg-indigo-500/30">
        <button
          :if={@sidebar_open}
          type="button"
          phx-click="toggle_sidebar"
          class="fixed inset-0 z-40 bg-black/70 backdrop-blur-sm md:hidden"
          aria-label="Close sidebar"
        >
        </button>

        <.sidebar view={@view} sidebar_open={@sidebar_open} />

        <main class="flex-1 h-screen overflow-y-auto">
          <.topbar view={@view} user={@user} />

          <div class="p-8 md:p-12 max-w-6xl mx-auto">
            <.dashboard_view
              :if={@view == "dashboard"}
              live_sessions={@live_sessions}
              appointments={@appointments}
            />
            <.posted_styles_view :if={@view == "posted_styles"} posted_styles={@posted_styles} />
            <.profile_view
              :if={@view == "profile"}
              user={@user}
              uploads={@uploads}
              password_form={@password_form}
              show_password={@show_password}
            />
            <.add_style_view
              :if={@view == "add_style"}
              style_form={@style_form}
              uploads={@uploads}
            />
          </div>
        </main>
      </div>
    </Layouts.app>
    """
  end

  attr :sidebar_open, :boolean, required: true
  attr :view, :string, required: true

  defp sidebar(assigns) do
    ~H"""
    <aside class={[
      "fixed md:static z-50 w-72 h-screen bg-slate-900/40 backdrop-blur-2xl border-r border-white/5 p-6 flex flex-col transition-transform duration-300",
      if(@sidebar_open, do: "translate-x-0", else: "-translate-x-full md:translate-x-0")
    ]}>
      <div class="flex items-center gap-3 mb-12 px-2">
        <div class="w-10 h-10 bg-indigo-600 rounded-xl flex items-center justify-center shadow-xl shadow-indigo-500/20">
          <span class="text-white font-black italic text-xl">H</span>
        </div>
        <h2 class="text-2xl font-black tracking-tighter text-white uppercase italic">
          Hair<span class="text-indigo-500">Zippiker</span>
        </h2>
      </div>

      <nav class="flex-1 space-y-2">
        <.nav_item
          phx-click="switch_view"
          phx-value-view="dashboard"
          active={@view == "dashboard"}
          icon="hero-squares-2x2"
        >
          Dashboard
        </.nav_item>
        <.nav_item
          phx-click="switch_view"
          phx-value-view="add_style"
          active={@view == "add_style"}
          icon="hero-plus-circle"
        >
          Add New Style
        </.nav_item>
        <.nav_item
          phx-click="switch_view"
          phx-value-view="posted_styles"
          active={@view == "posted_styles"}
          icon="hero-scissors"
        >
          Posted Hair Cuts
        </.nav_item>
        <.nav_item
          phx-click="switch_view"
          phx-value-view="profile"
          active={@view == "profile"}
          icon="hero-user"
        >
          Profile & Security
        </.nav_item>
      </nav>

      <div class="pt-6 border-t border-white/5">
        <.link
          href={~p"/users/log-out"}
          method="delete"
          class="flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-bold text-red-400 hover:bg-red-500/10 transition-all w-full"
        >
          <.icon name="hero-arrow-left-on-rectangle" class="w-5 h-5" /> Logout
        </.link>
      </div>
    </aside>
    """
  end

  attr :view, :string, required: true
  attr :user, :map, required: true

  defp topbar(assigns) do
    ~H"""
    <header class="sticky top-0 z-30 bg-[#050505]/80 backdrop-blur-md border-b border-white/5 px-8 py-5 flex items-center justify-between">
      <div class="flex items-center gap-4">
        <button
          type="button"
          phx-click="toggle_sidebar"
          class="flex h-11 w-11 items-center justify-center rounded-2xl border border-white/10 bg-white/5 text-white transition hover:bg-white/10 md:hidden"
          aria-label="Open sidebar"
        >
          <.icon name="hero-bars-3" class="h-6 w-6" />
        </button>
        <div class="flex flex-col">
          <h1 class="text-[10px] font-black text-slate-500 uppercase tracking-[0.2em] mb-1">
            {String.replace(@view, "_", " ")}
          </h1>
          <p class="text-white font-bold text-lg">{get_greeting(@user.full_name)}</p>
        </div>
      </div>
      <img
        src={profile_image_url(@user, 80)}
        class="w-10 h-10 rounded-full border border-white/10 object-cover"
      />
    </header>
    """
  end

  attr :live_sessions, :list, required: true
  attr :appointments, :list, required: true

  defp dashboard_view(assigns) do
    ~H"""
    <div class="grid lg:grid-cols-2 gap-8">
      <div class="space-y-6">
        <h3 class="text-xs font-black uppercase text-slate-500 tracking-widest px-2">
          Active Chair
        </h3>
        <%= for session <- @live_sessions do %>
          <div class="p-8 bg-indigo-600 rounded-[2.5rem] text-white flex justify-between items-center shadow-2xl shadow-indigo-600/40">
            <div>
              <p class="text-xs font-black uppercase opacity-70 mb-1">Currently Cutting</p>
              <h4 class="text-2xl font-black tracking-tight">{session.client}</h4>
            </div>
            <button class="bg-white text-indigo-600 font-black px-6 py-3 rounded-2xl uppercase text-xs hover:bg-slate-100 transition-colors">
              Finish
            </button>
          </div>
        <% end %>
        <div class="hidden only:flex min-h-40 items-center justify-center rounded-[2.5rem] border border-dashed border-white/10 bg-slate-900/30 p-8 text-center">
          <div>
            <.icon name="hero-scissors" class="mx-auto mb-4 h-10 w-10 text-slate-700" />
            <p class="text-xs font-black uppercase tracking-widest text-slate-500">
              No active chair right now
            </p>
          </div>
        </div>
      </div>

      <div class="space-y-6">
        <h3 class="text-xs font-black uppercase text-slate-500 tracking-widest px-2">
          Upcoming Bookings
        </h3>
        <div class="bg-slate-900/40 border border-white/5 rounded-[2.5rem] overflow-hidden p-2">
          <%= for appt <- @appointments do %>
            <div class="p-6 flex items-center justify-between hover:bg-white/5 rounded-2xl transition-all">
              <div class="flex items-center gap-4">
                <div class="w-12 h-12 rounded-xl bg-slate-950 border border-white/5 flex items-center justify-center text-indigo-500 font-black text-xs">
                  {format_booking_time(appt.scheduled_time)}
                </div>
                <div>
                  <p class="font-bold text-white">{appt.customer_name}</p>
                  <p class="text-xs text-slate-500 font-medium uppercase tracking-tighter">
                    {appt.service && appt.service.name}
                  </p>
                  <p class="mt-1 text-[10px] font-black uppercase tracking-widest text-slate-600">
                    {format_booking_date(appt.scheduled_date)}
                  </p>
                </div>
              </div>
              <.status_badge status={appt.status} />
            </div>
          <% end %>
          <div class="hidden only:flex min-h-40 items-center justify-center rounded-[2rem] border border-dashed border-white/10 p-8 text-center">
            <div>
              <.icon name="hero-calendar-days" class="mx-auto mb-4 h-10 w-10 text-slate-700" />
              <p class="text-xs font-black uppercase tracking-widest text-slate-500">
                No customer bookings yet
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :posted_styles, :list, required: true

  defp posted_styles_view(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <%= for style <- @posted_styles do %>
        <div class="bg-slate-900/40 border border-white/5 rounded-[2rem] overflow-hidden group hover:border-indigo-500/50 transition-all">
          <div class="h-48 bg-black relative">
            <%= if style.image_url do %>
              <img src={style.image_url} class="w-full h-full object-cover" />
            <% else %>
              <div class="w-full h-full flex items-center justify-center text-slate-700">
                <.icon name="hero-photo" class="w-12 h-12" />
              </div>
            <% end %>
            <div class="absolute top-4 right-4 bg-indigo-600 text-white text-xs font-black px-3 py-1 rounded-full shadow-lg">
              KSh {format_price(style.price)}
            </div>
          </div>
          <div class="p-6">
            <h4 class="text-xl font-black text-white italic uppercase tracking-tighter mb-2">
              {style.name}
            </h4>
            <p class="text-slate-500 text-sm line-clamp-2">{style.description}</p>
            <button
              id={"delete-style-#{style.id}"}
              type="button"
              phx-click="delete_style"
              phx-value-id={style.id}
              phx-confirm="Delete this posted hair cut?"
              class="mt-5 flex w-full items-center justify-center gap-2 rounded-2xl border border-red-500/20 bg-red-500/10 px-4 py-3 text-[10px] font-black uppercase tracking-widest text-red-300 transition hover:-translate-y-0.5 hover:border-red-400/50 hover:bg-red-500/20 hover:text-red-100"
            >
              <.icon name="hero-trash" class="h-4 w-4" /> Delete Style
            </button>
          </div>
        </div>
      <% end %>
      <div class="hidden only:flex min-h-64 items-center justify-center rounded-[2rem] border border-dashed border-white/10 bg-slate-900/30 p-8 text-center">
        <div>
          <.icon name="hero-scissors" class="mx-auto mb-4 h-10 w-10 text-slate-700" />
          <p class="text-xs font-black uppercase tracking-widest text-slate-500">
            No posted hair cuts yet
          </p>
        </div>
      </div>
    </div>
    """
  end

  attr :user, :map, required: true
  attr :uploads, :map, required: true
  attr :password_form, Phoenix.HTML.Form, required: true
  attr :show_password, :boolean, required: true

  defp profile_view(assigns) do
    ~H"""
    <div class="grid lg:grid-cols-5 gap-8">
      <div class="lg:col-span-2 space-y-8">
        <div class="bg-slate-900/40 border border-white/5 rounded-[2.5rem] p-10 text-center">
          <div class="relative inline-block mb-6">
            <form phx-change="validate_upload" phx-submit="save_profile_pic" id="profile-pic-form">
              <label
                for="profile_pic_input"
                class="cursor-pointer group relative block overflow-hidden rounded-[2.5rem]"
              >
                <img
                  src={profile_image_url(@user, 200)}
                  alt={@user.full_name || @user.email || "Profile picture"}
                  class="w-40 h-40 object-cover border-4 border-indigo-600/20 shadow-2xl transition-all group-hover:scale-110"
                />
                <div class="absolute inset-0 bg-indigo-600/40 opacity-0 group-hover:opacity-100 flex items-center justify-center transition-all">
                  <.icon name="hero-camera" class="w-8 h-8 text-white" />
                </div>
                <.live_file_input
                  upload={@uploads.profile_pic}
                  class="absolute inset-0 cursor-pointer opacity-0"
                  id="profile_pic_input"
                />
              </label>

              <%= for entry <- @uploads.profile_pic.entries do %>
                <div class="mt-4">
                  <.live_img_preview
                    entry={entry}
                    class="mx-auto mb-4 h-28 w-28 rounded-2xl object-cover"
                  />
                  <p class="text-[10px] text-indigo-400 font-black mb-2 uppercase">
                    Ready to save
                  </p>
                  <button
                    type="submit"
                    class="w-full py-3 bg-emerald-500 text-black font-black rounded-xl text-xs uppercase shadow-lg shadow-emerald-500/20"
                  >
                    Apply Changes
                  </button>
                </div>
              <% end %>

              <label
                for="profile_pic_input"
                class="mt-5 block w-full cursor-pointer rounded-xl border border-white/10 bg-white/5 px-5 py-3 text-center text-[10px] font-black uppercase tracking-widest text-slate-300 transition hover:bg-white/10 hover:text-white"
              >
                Choose Profile Picture
              </label>
            </form>
          </div>

          <div class="text-left space-y-4 mt-6">
            <.profile_field label="Full Name" value={@user.full_name} />
            <.profile_field label="Email" value={@user.email} italic />
          </div>
        </div>
      </div>

      <div class="lg:col-span-3 bg-slate-900/40 border border-white/5 rounded-[2.5rem] p-10">
        <h2 class="text-2xl font-black text-white italic uppercase tracking-tighter mb-10">
          Security Settings
        </h2>
        <.form for={@password_form} phx-submit="change_password" class="space-y-6">
          <div class="relative">
            <label class="text-[10px] font-black uppercase text-slate-500 tracking-widest ml-2 mb-2 block">
              New Password
            </label>
            <.input
              field={@password_form[:password]}
              type={if @show_password, do: "text", else: "password"}
              class="!h-16 !bg-black !border-white/5 !rounded-2xl !text-lg !px-6 focus:!border-indigo-500 w-full font-mono"
              placeholder="••••••••"
            />
            <button
              type="button"
              phx-click="toggle_password"
              class="absolute right-6 top-[3.2rem] text-slate-600 hover:text-white"
            >
              <.icon
                name={if @show_password, do: "hero-eye-slash", else: "hero-eye"}
                class="w-6 h-6"
              />
            </button>
          </div>
          <div class="space-y-2">
            <label class="text-[10px] font-black uppercase text-slate-500 tracking-widest ml-2">
              Confirm Password
            </label>
            <.input
              field={@password_form[:password_confirmation]}
              type={if @show_password, do: "text", else: "password"}
              class="!h-16 !bg-black !border-white/5 !rounded-2xl !text-lg !px-6 focus:!border-indigo-500 w-full font-mono"
              placeholder="••••••••"
            />
          </div>
          <button class="w-full h-16 bg-white text-black font-black uppercase tracking-widest text-xs rounded-2xl hover:scale-[1.01] transition-all">
            Update Password
          </button>
        </.form>
      </div>
    </div>
    """
  end

  attr :style_form, Phoenix.HTML.Form, required: true
  attr :uploads, :map, required: true

  defp add_style_view(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto bg-slate-900/40 border border-white/5 rounded-[2.5rem] p-10">
      <h2 class="text-3xl font-black text-white italic uppercase tracking-tighter mb-8 text-center">
        New Hairstyle
      </h2>
      <.form
        for={@style_form}
        id="staff-style-form"
        phx-submit="save_style"
        phx-change="validate_upload"
        class="space-y-8"
      >
        <div class="space-y-2">
          <label class="text-[10px] font-black uppercase text-slate-500 tracking-widest ml-2">
            Style Image
          </label>
          <label
            for="style-pic-input"
            phx-drop-target={@uploads.style_pic.ref}
            class="relative flex flex-col items-center justify-center w-full h-44 border-2 border-dashed border-white/10 rounded-[2rem] cursor-pointer bg-black/20 hover:bg-black/40 transition-all overflow-hidden"
          >
            <%= if Enum.empty?(@uploads.style_pic.entries) do %>
              <.icon name="hero-photo" class="w-10 h-10 text-slate-700 mb-2" />
              <p class="text-[10px] text-slate-500 font-black uppercase">
                Upload Reference Photo
              </p>
            <% else %>
              <%= for entry <- @uploads.style_pic.entries do %>
                <div class="relative w-full h-full flex items-center justify-center bg-black">
                  <.live_img_preview entry={entry} class="max-h-full object-contain" />
                  <div class="absolute bottom-2 bg-indigo-600 px-3 py-1 rounded-full text-[10px] font-black text-white">
                    Ready to add
                  </div>
                </div>
              <% end %>
            <% end %>
            <.live_file_input
              upload={@uploads.style_pic}
              id="style-pic-input"
              class="absolute inset-0 h-full w-full cursor-pointer opacity-0"
            />
          </label>
          <div :if={upload_errors(@uploads.style_pic) != []} class="space-y-1">
            <p
              :for={error <- upload_errors(@uploads.style_pic)}
              class="text-[10px] font-black uppercase tracking-widest text-red-400"
            >
              {upload_error_to_string(error)}
            </p>
          </div>
        </div>

        <.text_input name="name" label="Style Name" placeholder="e.g. Executive Fade" />
        <.text_input name="cost" type="number" label="Cost (KSh)" placeholder="1000" />
        <div class="space-y-2">
          <label class="text-[10px] font-black uppercase text-slate-500 tracking-widest ml-2">
            Description
          </label>
          <textarea
            name="note"
            rows="3"
            class="w-full bg-black border-white/5 rounded-2xl text-white p-6 focus:border-indigo-500 outline-none"
            placeholder="What's special about this cut?"
          ></textarea>
        </div>
        <button
          type="submit"
          class="w-full h-16 bg-indigo-600 text-white font-black uppercase tracking-widest text-sm rounded-2xl hover:bg-indigo-500 shadow-xl shadow-indigo-600/20 transition-all"
          phx-disable-with="Adding Hair Style..."
        >
          Add Hair Style
        </button>
      </.form>
    </div>
    """
  end

  attr :active, :boolean, default: false
  attr :icon, :string, required: true
  attr :rest, :global
  slot :inner_block, required: true

  defp nav_item(assigns) do
    ~H"""
    <button
      class={[
        "w-full flex items-center gap-3 px-5 py-4 rounded-2xl text-sm font-bold transition-all",
        if(@active,
          do: "bg-indigo-600 text-white shadow-xl shadow-indigo-600/20",
          else: "text-slate-500 hover:bg-white/5 hover:text-white"
        )
      ]}
      {@rest}
    >
      <.icon name={@icon} class="w-5 h-5" />
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :status, :string, default: "confirmed"

  defp status_badge(assigns) do
    ~H"""
    <span class="text-[9px] font-black uppercase tracking-widest px-3 py-1 rounded-full bg-emerald-500/10 text-emerald-500 border border-emerald-500/20">
      {@status}
    </span>
    """
  end

  attr :label, :string, required: true
  attr :value, :string, default: nil
  attr :italic, :boolean, default: false

  defp profile_field(assigns) do
    ~H"""
    <div>
      <label class="text-[10px] font-black uppercase text-slate-600 tracking-widest ml-1">
        {@label}
      </label>
      <div class={[
        "w-full h-14 bg-black/40 border border-white/5 rounded-xl flex items-center px-5 font-bold text-white",
        @italic && "italic"
      ]}>
        {@value}
      </div>
    </div>
    """
  end

  attr :name, :string, required: true
  attr :label, :string, required: true
  attr :type, :string, default: "text"
  attr :placeholder, :string, default: nil

  defp text_input(assigns) do
    ~H"""
    <div class="space-y-2">
      <label class="text-[10px] font-black uppercase text-slate-500 tracking-widest ml-2">
        {@label}
      </label>
      <input
        type={@type}
        name={@name}
        required
        class="w-full h-16 bg-black border-white/5 rounded-2xl text-white text-lg px-6 focus:border-indigo-500 outline-none"
        placeholder={@placeholder}
      />
    </div>
    """
  end

  defp get_greeting(name) when is_binary(name) and name != "" do
    first_name = name |> String.split(" ") |> List.first() |> String.capitalize()
    hour = DateTime.utc_now().hour + 3

    cond do
      hour >= 5 and hour < 12 -> "Good morning, #{first_name}"
      hour >= 12 and hour < 17 -> "Good afternoon, #{first_name}"
      hour >= 17 and hour < 21 -> "Good evening, #{first_name}"
      true -> "Goodnight, #{first_name}"
    end
  end

  defp get_greeting(_name), do: "Welcome back"

  defp profile_image_url(%{profile_picture_url: url}, _size) when is_binary(url) and url != "",
    do: url

  defp profile_image_url(user, size) do
    name = user.full_name || user.email || "Hair Zippiker"

    query =
      URI.encode_query(%{
        "name" => name,
        "size" => size,
        "background" => "6366f1",
        "color" => "fff"
      })

    "https://ui-avatars.com/api/?#{query}"
  end

  defp format_price(amount) when is_integer(amount) do
    amount
    |> Integer.to_charlist()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end

  defp format_price(amount) when is_binary(amount), do: amount
  defp format_price(_), do: "0"

  defp format_booking_date(%Date{} = date), do: Calendar.strftime(date, "%b %d, %Y")
  defp format_booking_date(_date), do: "No date"

  defp format_booking_time(%Time{} = time), do: Calendar.strftime(time, "%I:%M %p")
  defp format_booking_time(_time), do: "--:--"

  defp upload_error_to_string(:too_large), do: "Image is too large. Choose a smaller photo."
  defp upload_error_to_string(:too_many_files), do: "Choose only one image."
  defp upload_error_to_string(:not_accepted), do: "Use a JPG, JPEG, or PNG image."
  defp upload_error_to_string(error), do: "Upload failed: #{inspect(error)}"
end
