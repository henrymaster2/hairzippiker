# defmodule HairZippikerWeb.UserRegistrationLive do
#   use HairZippikerWeb, :live_view

#   alias HairZippiker.Accounts
#   alias HairZippiker.Accounts.User

#   def render(assigns) do
#     ~H"""
#     <main class="relative min-h-screen w-full overflow-y-auto bg-black font-sans text-white pb-20">
#       <div class="absolute inset-0 bg-gradient-to-b from-slate-900 via-black to-black opacity-90 z-0"></div>

#       <div class="relative z-10 flex flex-col items-center justify-center pt-20 px-6">

#         <div class="w-full max-w-lg bg-white/5 backdrop-blur-2xl border border-white/10 p-8 md:p-12 rounded-[40px] shadow-2xl shadow-blue-500/5">
#           <h2 class="text-3xl font-black uppercase italic tracking-tighter mb-2 text-center text-white">
#             Create an account
#           </h2>
#           <p class="text-white/40 text-[10px] text-center uppercase tracking-[0.3em] mb-10">
#             Enter your details to get started
#           </p>

#           <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate" class="space-y-6">

#             <%!-- Full Name --%>
#             <div>
#               <label class="text-[10px] font-black uppercase tracking-widest text-white/40 ml-2 mb-2 block">Full Name</label>
#               <.input field={@form[:full_name]} type="text" placeholder="John Doe" required
#                 class="w-full bg-white/5 border border-white/10 p-5 rounded-2xl text-white outline-none focus:border-blue-500 focus:ring-0 transition-all placeholder:text-white/10" />
#             </div>

#             <%!-- Email Address --%>
#             <div>
#               <label class="text-[10px] font-black uppercase tracking-widest text-white/40 ml-2 mb-2 block">Email Address</label>
#               <.input field={@form[:email]} type="email" placeholder="name@example.com" required
#                 class="w-full bg-white/5 border border-white/10 p-5 rounded-2xl text-white outline-none focus:border-blue-500 transition-all placeholder:text-white/10" />
#             </div>

#             <%!-- Phone Number --%>
#             <div>
#               <label class="text-[10px] font-black uppercase tracking-widest text-white/40 ml-2 mb-2 block">Phone Number</label>
#               <.input field={@form[:phone_number]} type="tel" placeholder="07XXXXXXXX" required
#                 class="w-full bg-white/5 border border-white/10 p-5 rounded-2xl text-white outline-none focus:border-blue-500 transition-all placeholder:text-white/10" />
#             </div>

#             <%!-- National ID --%>
#             <div>
#               <label class="text-[10px] font-black uppercase tracking-widest text-white/40 ml-2 mb-2 block">National ID</label>
#               <.input field={@form[:nid]} type="text" placeholder="ID Number" required
#                 class="w-full bg-white/5 border border-white/10 p-5 rounded-2xl text-white outline-none focus:border-blue-500 transition-all placeholder:text-white/10" />
#             </div>

#             <%!-- Password --%>
#             <div class="relative">
#               <label class="text-[10px] font-black uppercase tracking-widest text-white/40 ml-2 mb-2 block">Password</label>
#               <div class="relative flex items-center">
#                 <.input 
#                   field={@form[:password]} 
#                   type={if @show_password, do: "text", else: "password"} 
#                   placeholder="••••••••"
#                   required
#                   class="w-full bg-white/5 border border-white/10 p-5 pr-14 rounded-2xl text-white outline-none focus:border-blue-500 transition-all placeholder:text-white/10" 
#                 />
#                 <button type="button" phx-click="toggle-password" class="absolute right-5 z-20 text-white/20 hover:text-blue-500 transition-colors">
#                   <%= if @show_password do %>
#                     <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"/><path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"/><path d="M6.61 6.61A13.52 13.52 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"/><line x1="2" x2="22" y1="2" y2="22"/></svg>
#                   <% else %>
#                     <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
#                   <% end %>
#                 </button>
#               </div>
#             </div>

#             <%!-- Confirm Password --%>
#             <div>
#               <label class="text-[10px] font-black uppercase tracking-widest text-white/40 ml-2 mb-2 block">Confirm Password</label>
#               <.input 
#                 field={@form[:password_confirmation]} 
#                 type={if @show_password, do: "text", else: "password"} 
#                 placeholder="••••••••"
#                 required
#                 class="w-full bg-white/5 border border-white/10 p-5 rounded-2xl text-white outline-none focus:border-blue-500 transition-all placeholder:text-white/10" 
#               />
#             </div>

#             <button type="submit" phx-disable-with="Creating..." class="w-full py-5 bg-blue-600 text-white font-black uppercase tracking-[0.2em] text-[11px] rounded-2xl shadow-xl shadow-blue-900/40 mt-6 active:scale-95 hover:bg-blue-500 transition-all">
#               Create Account
#             </button>
#           </.form>

#           <div class="mt-8 text-center border-t border-white/5 pt-8">
#             <p class="text-white/20 text-[10px] font-black uppercase tracking-widest">
#               Already have an account? <a href="/users/log-in" class="text-blue-500 hover:text-blue-400 ml-1">Sign In</a>
#             </p>
#           </div>
#         </div>

#         <a href="/" class="mt-8 text-white/20 text-[10px] font-black uppercase tracking-widest hover:text-white transition-all">
#           ← Back to Homepage
#         </a>
#       </div>
#     </main>
#     """
#   end

#   def mount(_params, _session, socket) do
#     changeset = Accounts.change_user_registration(%User{role: "employee"})

#     socket =
#       socket
#       |> assign(trigger_submit: false, check_errors: false)
#       |> assign(show_password: false)
#       |> assign_form(changeset)

#     {:ok, socket}
#   end

#   def handle_event("validate", %{"user" => user_params}, socket) do
#     changeset = Accounts.change_user_registration(%User{}, user_params)
#     {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
#   end

#   def handle_event("save", %{"user" => user_params}, socket) do
#     case Accounts.register_user(user_params) do
#       {:ok, _user} ->
#         {:noreply,
#          socket
#          |> put_flash(:info, "Account created successfully!")
#          |> redirect(to: ~p"/users/log-in")}

#       {:error, %Ecto.Changeset{} = changeset} ->
#         {:noreply, socket |> assign_form(changeset)}
#     end
#   end

#   def handle_event("toggle-password", _params, socket) do
#     {:noreply, assign(socket, show_password: !socket.assigns.show_password)}
#   end

#   defp assign_form(socket, %Ecto.Changeset{} = changeset) do
#     form = Phoenix.Component.to_form(changeset, as: "user")
#     assign(socket, form: form)
#   end
# end
