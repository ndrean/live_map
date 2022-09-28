defmodule LiveMapWeb.MailController do
  use LiveMapWeb, :controller
  require Logger

  @doc """
  Creates a new "event_participants" record, set a new token and the status to "pending"
  and sends a mail to the owner of the event.

  ```
  iex> LiveMapWeb.MailController.create(%{event_id: 1, user_id: 3})
  {:ok, %{id: "254672b8d21a7da71252feb059814b53"}}

  # navigate to http://localhost:4000/dev/mailbox, check the mail and click the link
  # you should get "confirmed"
  # check the Repo
  iex>LiveMap.EventParticipants.with_evt_id(1)
  # you shoudl have confirmed
  """
  def create(params = %{event_id: event_id, user_id: user_id}) do
    with token <- LiveMap.EventParticipants.set_pending(%{event_id: event_id, user_id: user_id}) do
      params = Map.put(params, :mtoken, token)

      LiveMapWeb.DemandeParticipate.build(params)
      |> LiveMap.Mailer.deliver()
    else
      {:error, %{errors: _msg}} ->
        Logger.error("#{__MODULE__}: has already been taken")
    end
  end
end
