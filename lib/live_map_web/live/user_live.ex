# defmodule LiveMapWeb.UserLive do
#   use Phoenix.LiveView

#   def mount(_, _, socket) do
#     {:ok, assign(socket, :place, nil)}
#   end

#   def render(assigns) do
#     IO.inspect(assigns, label: "user")

#     ~H"""
#     <section class="phx-hero">
#       <h1> Welcome
#       </h1>
#       <p> You are <strong>signed in</strong>
#         with your <strong>Github Account</strong> <br />
#         <strong style="color:teal;">yoyo</strong>
#       </p>
#     </section>
#     <section>
#       <button id="add_marker" phx_click="push_marker">Push marker</button>
#       <MapLive.LMap.display />
#     </section>
#     """
#   end
# end
