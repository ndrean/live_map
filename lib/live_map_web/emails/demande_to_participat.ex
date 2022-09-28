defmodule LiveMapWeb.DemandeParticipate do
  use Phoenix.Swoosh, view: LiveMapWeb.DemandeParticipateView

  @from "support@LiveMap.com"

  def build(%{mtoken: mtoken, event_id: event_id, user_id: user_id} = _params) do
    [email] = LiveMap.Event.owner(event_id)
    user_email = LiveMap.Repo.get_by(LiveMap.User, %{id: user_id}).email
    # url = auth_email_url(PwdlessGsWeb.Endpoint, :show, [], token: token)
    # new()
    %Swoosh.Email{}
    |> to(email)
    |> from(@from)
    |> subject("Demande to participate")
    |> assign(:token, mtoken)
    |> assign(:user_email, user_email)
    |> render_body("demande_link.html")
  end
end
