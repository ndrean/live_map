defmodule LiveMapWeb.MailController do
  use LiveMapWeb, :controller
  require Logger
  alias LiveMapMail.Email
  alias LiveMapMail.Mailer
  alias LiveMap.EventParticipants
  alias LiveMap.Token

  @doc """
  This function is triggered from the front-end when a user clicks on the button "request to participate" to an event.
  The owner of an event will receive a link in a mail generated by a user.
  The endpoint of this link triggers this function.
  This creates a new "event_participants" record, set a new token and the status to "pending"
  and sends a mail to the owner of the event.
  ```
  iex> LiveMapWeb.MailController.create(%{event_id: 1, user_id: 2})
  {:ok, #PID<0.861.0>}
  # navigate to http://localhost:4000/dev/mailbox, check the mail and click the link
  # you should get "confirmed"
  # check in iex
  iex>
  UPDATE "event_participants" SET "mtoken" = $1, "status" = $2, "updated_at" = $3 WHERE "id" = $4
  [nil, "confirmed", ~N[2022-09-29 14:55:09], 6]
  iex>LiveMap.EventParticipants.email_with_evt_id(1)
  %{ep_status: "confirmed", user_email: "bibi", user_id: 2}
  ```
  """
  def create(params = %{event_id: event_id, user_id: user_id}) do
    with token <- EventParticipants.set_pending(%{event_id: event_id, user_id: user_id}) do
      params = Map.put(params, :mtoken, token)

      Task.Supervisor.start_child(LiveMap.AsyncMailSup, fn ->
        Email.build_demand(params)
        |> Mailer.deliver()
      end)
    else
      {:error, %{errors: _msg}} ->
        Logger.error("#{__MODULE__}: has already been taken")
    end
  end

  defp fetch_token(conn, row) when is_nil(row) do
    json(conn, "Not found")
  end

  defp fetch_token(_conn, row) do
    row.mtoken
  end

  defp check_token(conn, mtoken) do
    with {:ok, string} <- Token.mail_check(mtoken) do
      {:ok, string}
    else
      {:error, :invalid} ->
        json(conn, "token invalid")
    end
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
    with {:ok, string} <- check_token(conn, token) do
      %{"event_id" => event_id, "user_id" => user_id} = URI.decode_query(string)
      event_id = String.to_integer(event_id)
      user_id = String.to_integer(user_id)
      row = EventParticipants.lookup(event_id, user_id)
      owner_mtoken = fetch_token(conn, row)

      case owner_mtoken do
        nil ->
          json(conn, "Already confirmed")
          |> halt()

        ^owner_mtoken ->
          Task.Supervisor.start_child(LiveMap.AsyncMailSup, fn ->
            {:ok, _} = EventParticipants.set_confirmed(%{event_id: event_id, user_id: user_id})

            Email.confirm_participation(%{
              event_id: event_id,
              user_id: user_id
            })
            |> Mailer.deliver()
          end)

          json(conn, "confirmed")
          |> halt()
      end
    end
  end
end
