defmodule LiveMapMail.Email do
  require Logger

  @moduledoc """
  Mail sender module.

  Two functions are exposed:
  - `build_demand` when a user demands to participate,
  - `confirm_participation` when the owner confirms the participation.
  """

  use Phoenix.Swoosh, view: LiveMapWeb.EmailView
  alias LiveMapMail.Mailer

  @support "support@LiveMap.com"

  @doc """
  Sends an email on behalf of the demandeur to the owner to participate to the event.

  This function receives a `token`, the `event_id` and `user_id`.
  The function finds the "owner email" and send him a mail with a `token` or "magic link".
  """
  def build_demand(%{mtoken: mtoken, event_id: event_id, user_id: user_id} = _params) do
    Logger.info("Sending demand mail")
    [email] = LiveMap.Event.owner(event_id)
    user_email = LiveMap.Repo.get_by(LiveMap.User, %{id: user_id}).email
    [date, addr_start, addr_end] = LiveMap.Event.details(event_id)

    %Swoosh.Email{}
    |> to(email)
    |> from(@support)
    |> subject("Demande to participate")
    |> assign(:token, mtoken)
    |> assign(:user_email, user_email)
    |> assign(:date, date)
    |> assign(:addr_start, addr_start)
    |> assign(:addr_end, addr_end)
    |> render_body("demande.html")
    |> Mailer.deliver()
  end

  @doc """
  Fills a template and sends a mail to the user.

  The function receives `user_id`, `event_id`, `subject` and `rendered_body`.

  It makes a lookup in the database.
  """

  def handle_email(%{
        event_id: event_id,
        user_id: user_id,
        subject: subject,
        rendered_body: rendered_body
      }) do
    %{owner: owner, user: user, date: date, addr_start: addr_start, addr_end: addr_end} =
      LiveMap.EventParticipants.owner_user_by_evt_id_user_id(event_id, user_id)

    %Swoosh.Email{}
    |> to(user)
    |> from(@support)
    |> subject(subject)
    |> assign(:date, date)
    |> assign(:user, user)
    |> assign(:owner, owner)
    |> assign(:addr_start, addr_start)
    |> assign(:addr_end, addr_end)
    |> render_body(rendered_body)
    |> Mailer.deliver()
  end
end
