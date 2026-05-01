defmodule HairZippikerWeb.AdminInventoryLive do
  use HairZippikerWeb, :live_view

  alias HairZippiker.Cloudinary
  alias HairZippiker.Inventory
  require Logger

  def mount(_params, _session, socket) do
    items = Inventory.list_products()

    {:ok,
     socket
     |> assign(page_title: "Inventory")
     |> assign(show_form: false)
     |> assign(dark_mode: true)
     |> assign(mobile_menu_open: false)
     |> assign(items: items)
     |> assign(preview: %{"name" => "", "type" => "", "s_p" => "", "qty" => ""})
     |> allow_upload(:product_image, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  # SAVE ITEM
  def handle_event(
        "save_item",
        %{"name" => n, "type" => t, "b_p" => b, "s_p" => s, "qty" => q},
        socket
      ) do
    {uploaded_urls, upload_notice} = consume_product_image(socket)
    image_url = List.first(Enum.reject(uploaded_urls, &is_nil/1))

    save_product(
      socket,
      %{
        "name" => n,
        "type" => t,
        "stock" => parse_integer(q),
        "buying_price" => parse_float(b),
        "selling_price" => parse_float(s),
        "image_url" => image_url
      },
      upload_notice
    )
  end

  def handle_event("delete_item", %{"id" => id}, socket) do
    case Inventory.delete_product(id) do
      {:ok, _} ->
        items = Inventory.list_products()
        {:noreply, assign(socket, items: items)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete item")}
    end
  end

  def handle_event("validate", params, socket) do
    {:noreply, assign(socket, preview: params)}
  end

  def handle_event("toggle_form", _params, socket) do
    {:noreply, assign(socket, show_form: !socket.assigns.show_form)}
  end

  def handle_event("toggle-theme", _params, socket) do
    {:noreply, assign(socket, dark_mode: !socket.assigns.dark_mode)}
  end

  def handle_event("toggle-mobile-menu", _params, socket) do
    {:noreply, assign(socket, mobile_menu_open: !socket.assigns.mobile_menu_open)}
  end

  # --- HELPERS ---

  defp save_product(socket, product_attrs, upload_notice) do
    case Inventory.create_product(product_attrs) do
      {:ok, _product} ->
        items = Inventory.list_products()
        flash_message = upload_notice || "Product saved successfully"

        {:noreply,
         socket
         |> assign(items: items)
         |> assign(show_form: false)
         |> assign(preview: %{"name" => "", "type" => "", "s_p" => "", "qty" => ""})
         |> put_flash(:info, flash_message)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not save product. Check your inputs.")}
    end
  end

  defp consume_product_image(socket) do
    uploaded_urls =
      try do
        consume_uploaded_entries(socket, :product_image, fn %{path: path}, entry ->
          case Cloudinary.upload(path, entry.client_name) do
            {:ok, url} ->
              {:ok, url}

            {:error, reason} ->
              Logger.error("Product image upload failed: #{inspect(reason)}")
              {:ok, nil}
          end
        end)
      catch
        :exit, reason ->
          Logger.error("Product image upload consume failed: #{inspect(reason)}")
          []
      end

    upload_notice =
      if uploaded_urls == [] do
        "Product saved, but no image was uploaded. Choose the image again if needed."
      end

    {uploaded_urls, upload_notice}
  end

  # Safely parse integers
  defp parse_integer(val) when is_binary(val) do
    case Integer.parse(val) do
      {num, _} -> num
      :error -> 0
    end
  end

  defp parse_integer(_), do: 0

  # Safely parse floats (handles "200" and "200.50")
  defp parse_float(val) when is_binary(val) do
    case Float.parse(val) do
      {num, _} -> num / 1.0
      :error -> 0.0
    end
  end

  defp parse_float(_), do: 0.0

  defp format_price(amount) when is_binary(amount) and amount != "", do: amount

  defp format_price(amount) when is_number(amount) do
    amount
    |> round()
    |> Integer.to_charlist()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end

  defp format_price(_), do: "0"

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
              <.nav_link href={~p"/admin/staff"} active={false}>Staff</.nav_link>
              <.nav_link href={~p"/admin/inventory"} active={true}>Inventory</.nav_link>
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
                <h1 class="title">Inventory</h1>
                <p class="subtitle">Track salon products, pricing, stock, and product media</p>
              </div>

              <button phx-click="toggle_form" class="primary-btn" id="inventory-form-toggle">
                {if @show_form, do: "Close Form", else: "Add Product"}
              </button>
            </header>

            <section class="stats-grid">
              <div class="card">
                <p class="label">Products</p>
                <h2 class="value">{length(@items)}</h2>
              </div>
              <div class="card">
                <p class="label">Stock Units</p>
                <h2 class="value">{total_stock(@items)}</h2>
              </div>
            </section>

            <%= if @show_form do %>
              <section class="inventory-form-grid">
                <div class="card form-stack">
                  <div>
                    <h2 class="section-title">Product Details</h2>
                    <p class="field-help">Add stock, prices, and an image for the shop inventory.</p>
                  </div>

                  <form
                    phx-change="validate"
                    phx-submit="save_item"
                    class="form-stack"
                    id="inventory-product-form"
                  >
                    <div class="form-grid">
                      <label>
                        <span class="label">Product name</span>
                        <input name="name" value={@preview["name"]} required class="admin-input" />
                      </label>
                      <label>
                        <span class="label">Type</span>
                        <input name="type" value={@preview["type"]} required class="admin-input" />
                      </label>
                    </div>

                    <div class="form-grid three">
                      <label>
                        <span class="label">Buying price</span>
                        <input
                          name="b_p"
                          value={@preview["b_p"]}
                          type="number"
                          step="any"
                          required
                          class="admin-input"
                        />
                      </label>
                      <label>
                        <span class="label">Selling price</span>
                        <input
                          name="s_p"
                          value={@preview["s_p"]}
                          type="number"
                          step="any"
                          required
                          class="admin-input"
                        />
                      </label>
                      <label>
                        <span class="label">Stock</span>
                        <input
                          name="qty"
                          value={@preview["qty"]}
                          type="number"
                          required
                          class="admin-input"
                        />
                      </label>
                    </div>

                    <div class="upload-box">
                      <p class="label">Media Upload</p>
                      <.live_file_input upload={@uploads.product_image} />
                    </div>

                    <button type="submit" class="primary-btn">Sync to Database</button>
                  </form>
                </div>

                <aside class="card preview-card">
                  <div class="preview-image">
                    <%= for entry <- @uploads.product_image.entries do %>
                      <.live_img_preview entry={entry} class="preview-img" />
                    <% end %>
                  </div>
                  <div>
                    <p class="label">Preview</p>
                    <h3 class="product-title">
                      {if @preview["name"] != "", do: @preview["name"], else: "New Product"}
                    </h3>
                    <p class="price">KSh {format_price(@preview["s_p"])}</p>
                  </div>
                </aside>
              </section>
            <% end %>

            <section class="product-grid" id="inventory-products">
              <%= for item <- @items do %>
                <article class="card product-card" id={"inventory-product-#{item.id}"}>
                  <div class="product-image">
                    <%= if item.image_url do %>
                      <img src={item.image_url} class="product-img" />
                    <% else %>
                      <span class="image-placeholder">{initial(item.name)}</span>
                    <% end %>

                    <button
                      phx-click="delete_item"
                      phx-value-id={item.id}
                      class="delete-btn"
                      aria-label="Delete product"
                    >
                      Delete
                    </button>
                  </div>

                  <div>
                    <h3 class="product-title">{item.name}</h3>
                    <p class="product-type">{item.type}</p>
                  </div>

                  <div class="product-meta">
                    <p class="price">KSh {format_price(item.selling_price)}</p>
                    <span class="stock">{item.stock} Units</span>
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
      .stats-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 18px; margin-bottom: 18px; }
      .card { padding: 22px; border-radius: 22px; background: linear-gradient(180deg, var(--glass-strong), var(--glass)); border: 1px solid var(--border); backdrop-filter: blur(18px); transition: 0.25s ease; }
      .card:hover { transform: translateY(-3px); border-color: rgba(59,130,246,0.25); }
      .label { display: block; font-size: 11px; color: var(--muted); text-transform: uppercase; margin-bottom: 8px; }
      .value { font-size: 38px; font-weight: 900; margin-top: 10px; }
      .form-stack { display: grid; gap: 16px; }
      .form-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; }
      .form-grid.three { grid-template-columns: repeat(3, minmax(0, 1fr)); }
      .section-title { font-size: 18px; font-weight: 900; margin-bottom: 4px; }
      .field-help { font-size: 12px; color: var(--muted); }
      .admin-input { width: 100%; border-radius: 14px; border: 1px solid var(--border); background: rgba(255,255,255,0.06); color: var(--text); padding: 13px 14px; outline: none; transition: 0.2s ease; }
      .admin-input:focus { border-color: rgba(59,130,246,0.65); box-shadow: 0 0 0 4px rgba(59,130,246,0.12); }
      .primary-btn { width: fit-content; border: none; border-radius: 14px; background: linear-gradient(135deg, #3b82f6, #2563eb); color: white; padding: 12px 16px; font-size: 12px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.08em; cursor: pointer; transition: 0.2s ease; }
      .primary-btn:hover { transform: translateY(-1px); box-shadow: 0 14px 28px rgba(59,130,246,0.22); }
      .inventory-form-grid { display: grid; grid-template-columns: 1.35fr 0.65fr; gap: 18px; align-items: start; margin-bottom: 18px; }
      .upload-box { border: 1px dashed rgba(59,130,246,0.35); border-radius: 18px; padding: 22px; background: rgba(59,130,246,0.06); }
      .preview-card { display: grid; gap: 16px; }
      .preview-image, .product-image { position: relative; overflow: hidden; aspect-ratio: 1; border-radius: 18px; background: rgba(15,23,42,0.7); display: flex; align-items: center; justify-content: center; }
      .preview-img, .product-img { width: 100%; height: 100%; object-fit: cover; transition: 0.5s ease; }
      .product-grid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 16px; }
      .product-card { display: grid; gap: 14px; }
      .product-card:hover .product-img { transform: scale(1.06); }
      .product-title { font-size: 16px; font-weight: 900; overflow-wrap: anywhere; }
      .product-type { color: var(--muted); font-size: 11px; text-transform: uppercase; letter-spacing: 0.12em; margin-top: 4px; }
      .product-meta { display: flex; justify-content: space-between; align-items: end; gap: 10px; }
      .price { color: var(--accent); font-size: 15px; font-weight: 900; }
      .stock { color: var(--muted); font-size: 10px; font-weight: 900; text-transform: uppercase; white-space: nowrap; }
      .image-placeholder { color: var(--accent); font-size: 42px; font-weight: 900; }
      .delete-btn { position: absolute; top: 10px; right: 10px; border: 1px solid rgba(239,68,68,0.35); background: rgba(0,0,0,0.55); color: #ef4444; border-radius: 999px; padding: 7px 10px; font-size: 10px; font-weight: 900; opacity: 0; transition: 0.2s ease; }
      .product-card:hover .delete-btn { opacity: 1; }
      @media (max-width: 1100px) { .product-grid { grid-template-columns: repeat(3, minmax(0, 1fr)); } }
      @media (max-width: 900px) { .layout { flex-direction: column; } .mobile-bar { display: flex; } .sidebar { position: fixed; top: 0; left: 0; height: 100%; transform: translateX(-100%); transition: 0.3s; z-index: 100; } .sidebar.open { transform: translateX(0); } .main { padding: 20px; } .header { align-items: stretch; flex-direction: column; } .stats-grid, .inventory-form-grid, .form-grid, .form-grid.three { grid-template-columns: 1fr; } .product-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); } .title { font-size: 34px; } }
      @media (max-width: 560px) { .product-grid { grid-template-columns: 1fr; } }
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

  defp total_stock(items) do
    Enum.reduce(items, 0, fn item, total -> total + (item.stock || 0) end)
  end

  defp initial(value) when is_binary(value), do: value |> String.first() |> String.upcase()
  defp initial(_value), do: "P"
end
