defmodule LiveMapMail.Email do
  use Phoenix.Swoosh, view: LiveMapMail.EmailView

  @support "support@LiveMap.com"

  @doc """
  This function receives a token, the event_id and user_id.
  From this, we find the owner email and send him a mail with a magic link.
  """
  def build_demand(%{mtoken: mtoken, event_id: event_id, user_id: user_id} = _params) do
    [email] = LiveMap.Event.owner(event_id)
    user_email = LiveMap.Repo.get_by(LiveMap.User, %{id: user_id}).email

    %Swoosh.Email{}
    |> to(email)
    |> from(@support)
    |> subject("Demande to participate")
    |> assign(:token, mtoken)
    |> assign(:user_email, user_email)
    |> render_body("demande.html")
  end

  @doc """
  Sends a mail to the user on behalf of the owner to confirm the event.
  The function receives [user_id, event_id], makes a lookup for the corresponding
  owner.email and user.email and event.date and sends a confirmation mail.
  """
  def confirm_participation(%{user_id: user_id, event_id: event_id}) do
    %{owner: owner, user: user, date: date} =
      LiveMap.EventParticipants.owner_user_by_evt_id_user_id(event_id, user_id)

    %Swoosh.Email{}
    |> to(user)
    |> from(@support)
    |> subject("Confirmation to the event")
    |> assign(:date, date)
    |> assign(:user, user)
    |> assign(:owner, owner)
    |> render_body("confirmation.html")
  end
end
