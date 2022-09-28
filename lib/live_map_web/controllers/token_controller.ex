defmodule LiveMapWeb.TokenController do
  use LiveMapWeb, :controller

  defp lookup(event_id, user_id) do
    LiveMap.Repo.get_by(LiveMap.EventParticipants, %{event_id: event_id, user_id: user_id})
  end

  defp fetch_token(conn, row) when is_nil(row) do
    json(conn, "Not found")
  end

  defp fetch_token(_conn, row) do
    row.mtoken
  end

  defp check_token(conn, mtoken) do
    with {:ok, string} <- LiveMap.Token.mail_check(mtoken) do
      {:ok, string}
    else
      {:error, :invalid} ->
        json(conn, "token invalid")
    end
  end

  @doc """
  Compares the received query string and extracts the token stored for [user_id, event_id]
  ```
  >
  > curl localhost:4000/mail/token="SFMyNTY.g2gDbQAAABR1c2VyX2lkPTEmZX..."
  """
  def confirm_link(conn, %{"token" => token} = _params) do
    # %{"token" => mtoken} = URI.decode_query(token)

    with {:ok, string} <- check_token(conn, token) do
      %{"event_id" => event_id, "user_id" => user_id} = URI.decode_query(string)
      row = lookup(event_id, user_id)
      owner_mtoken = fetch_token(conn, row)

      case owner_mtoken do
        nil ->
          json(conn, "Already confirmed")

        ^owner_mtoken ->
          {:ok, _} =
            LiveMap.EventParticipants.set_confirmed(%{event_id: event_id, user_id: user_id})

          json(conn, "confirmed")
      end
    end
  end
end
