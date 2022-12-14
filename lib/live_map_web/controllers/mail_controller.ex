defmodule LiveMapWeb.MailController do
  use LiveMapWeb, :controller
  require Logger
  alias LiveMapMail.Email
  alias LiveMap.EventParticipants
  alias LiveMap.Token

  @doc """
  This function is triggered from the front-end when a user clicks on the button "request to participate" to an event.
  The owner of an event will receive a link in a mail generated by a user.
  The endpoint of this link triggers this function.
  This creates a new "event_participants" record, set a new token and the status to "pending"
  and sends a mail to the owner of the event.

  ### Examples
    iex> LiveMapMail.MailController.create_demand(%{event_id: 1, user_id: 2})
    # {:ok, #PID<0.861.0>}
    # navigate to http://localhost:4000/dev/mailbox, check the mail and click the link
    # you should get "confirmed"
    # check in iex

    iex>
    UPDATE "event_participants" SET "mtoken" = $1, "status" = $2, "updated_at" = $3 WHERE "id" = $4
    # [nil, "confirmed", ~N[2022-09-29 14:55:09], 6]

    iex>LiveMap.EventParticipants.email_with_evt_id(1)
    # %{ep_status: "confirmed", user_email: "bibi", user_id: 2}
    ```
  """
  def create_demand(%{event_id: event_id, user_id: user_id} = params) do
    token = EventParticipants.set_pending(%{event_id: event_id, user_id: user_id})

    Map.put(params, :mtoken, token)
    |> Email.build_demand()
  end

  defp check_token(mtoken) do
    case Token.mail_check(mtoken) do
      {:ok, string} -> {:ok, string}
      {:error, message} -> {:error, message}
    end
  end

  def cancel_event(%{event_id: id}) do
    Logger.info("sending cancel mail ********")

    LiveMap.Event.get_event_participants(id)
    |> Enum.each(fn %{status: status, user_id: user_id} ->
      if status != "owner" do
        Email.handle_email(%{
          event_id: id,
          user_id: user_id,
          subject: "Cancel the event",
          rendered_body: "cancel_event.html"
        })
      end
    end)
  end

  @doc """
  The owner of an event receives a link in a mail generated by a user.
  The endpoint of this link triggers this function.
  The decrypted token contains the details to retrieve an "event_participants" record: [event_id, user_id]
  We compare the received token to one saved in the DB.
  ```
  # test it with a crypted token you get fro mthe DB:
  iex> LiveMap.EventParticipants.set_pending(%{user_id: 1, event_id: 1})
  "SFMyNTY.g2gDbQAAABR1c2VyX2lkPTEmZ..."
  iex> LiveMpa.EventPArticipants.lookup(1,1)
  %LiveMap.EventParticipants{
    id: 5, user_id: 1, event_id: 1, mtoken: "SFMyNTY.g2gDbQAAABR1c2VyX2lkPTE...",
    status: :pending,
  }
  $> curl localhost:4000/mail/token="SFMyNTY.g2gDbQAAABR1c2VyX2lkPTEmZ..."
  "confirmed"
  iex> LiveMap.EventParticipants.lookup(1,1)
  %LiveMap.EventParticipants{
    id: 5, user_id: 1, event_id: 1, mtoken: nil,
    status: :confirmed,
  }
  # test again the endpoint:
  $> curl localhost:4000/mail/token="SFMyNTY.g2gDbQAAABR1c2VyX2lkPTEmZ..."
  "Already confirmed"
  ```
  """
  def confirm_link(conn, %{"token" => token} = _params) do
    case check_token(token) do
      {:ok, string} ->
        %{"event_id" => event_id, "user_id" => user_id} = URI.decode_query(string)
        handle_token(conn, event_id, user_id)

      {:error, reason} ->
        put_flash(conn, :info, "Error with the token: #{inspect(reason)}")
    end
  end

  def handle_token(conn, event_id, user_id) do
    event_id = String.to_integer(event_id)
    user_id = String.to_integer(user_id)

    case EventParticipants.lookup(event_id, user_id) do
      nil ->
        json(conn, "lost in translation OO")
        |> halt()

      row ->
        handle_owner_token(conn, row.mtoken, event_id, user_id)
    end
  end

  defp handle_owner_token(conn, nil, _, _) do
    json(conn, "Event deleted or Already confirmed")
    |> halt()
  end

  defp handle_owner_token(conn, _, event_id, user_id) do
    Task.Supervisor.start_child(LiveMap.AsyncMailSup, fn ->
      case EventParticipants.set_confirmed(%{event_id: event_id, user_id: user_id}) do
        {:error, :not_found} ->
          json(conn, "lost in translation 22")
          |> halt()

        {:ok, _res} ->
          Logger.info("Sending confirmation mail")

          Email.handle_email(%{
            event_id: event_id,
            user_id: user_id,
            subject: "Confirmation to the event",
            rendered_body: "confirmation.html"
          })
      end
    end)

    json(conn, "confirmed")
    |> halt()
  end
end
