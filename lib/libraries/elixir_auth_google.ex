defmodule Libraries.ElixirAuthGoogle do
  @google_auth_url "https://accounts.google.com/o/oauth2/v2/auth?response_type=code"
  @google_token_url "https://oauth2.googleapis.com/token"
  @google_user_profile "https://www.googleapis.com/oauth2/v3/userinfo"
  @default_scope "profile email"
  @default_callback_path "/auth/google/callback"

  def get_baseurl_from_conn(%{host: h, port: p}) when h == "localhost" do
    # "http://#{h}:#{p}"
    (p != 4000 && "https://localhost") || "http://" <> h <> ":#{p}"
  end

  def get_baseurl_from_conn(%{host: h}), do: "https://" <> h

  def generate_redirect_uri(conn) do
    get_baseurl_from_conn(conn) <> get_app_callback_url()
  end

  def generate_oauth_url(conn) do
    query = %{
      client_id: google_client_id(),
      scope: google_scope(),
      redirect_uri: generate_redirect_uri(conn)
    }

    params = URI.encode_query(query, :rfc3986)
    # @google_auth_url <> "&" <> params
    "#{@google_auth_url}&#{params}"
  end

  # def generate_oauth_url(conn, state) when is_binary(state) do
  #   params = URI.encode_query(%{state: state}, :rfc3986)
  #   generate_oauth_url(conn) <> "&" <> params
  # end

  @doc """
  `get_token/2` encodes the secret keys and authorization code returned by Google
  and issues an HTTP request to get a person's profile data.
  **TODO**: we still need to handle the various failure conditions >> issues/16
  """

  def get_profile(code, conn) do
    Jason.encode!(%{
      client_id: google_client_id(),
      client_secret: google_client_secret(),
      redirect_uri: generate_redirect_uri(conn),
      grant_type: "authorization_code",
      code: code
    })
    |> then(fn body ->
      HTTPoison.post(@google_token_url, body)
      |> parse_status()
      |> parse_response()
    end)
  end

  def parse_status({:ok, %{status_code: 200}} = response), do: parse_body_response(response)

  # def parse_status({:ok, _}), do: {:error, :bad_input}

  # or the more verbose error status catcher:
  def parse_status({:ok, status}) do
    case status do
      %{status_code: 404} -> {:error, :wrong_url}
      %{status_code: 401} -> {:error, :unauthorized}
      %{status_code: 400} -> {:error, :wrong_code}
      _ -> {:error, :unknown_error}
    end
  end

  def parse_body_response({:error, err}), do: {:error, err}
  def parse_body_response({:ok, %{body: nil}}), do: {:error, :no_body}

  def parse_body_response({:ok, %{body: body}}) do
    {:ok,
     body
     |> Jason.decode!()
     |> convert()}
  end

  defp convert(str_key_map) do
    for {key, val} <- str_key_map, into: %{}, do: {String.to_atom(key), val}
  end

  def parse_response({:error, response}), do: {:error, response}
  def parse_response({:ok, response}), do: get_user_profile(response.access_token)

  def get_user_profile(access_token) do
    access_token
    |> encode()
    |> then(fn params ->
      (@google_user_profile <> "?" <> params)
      |> HTTPoison.get()
      |> parse_status()
    end)
  end

  defp encode(token), do: URI.encode_query(%{access_token: token}, :rfc3986)

  ##################
  defp google_client_id do
    System.get_env("GOOGLE_CLIENT_ID") || Application.get_env(:elixir_auth_google, :client_id)
  end

  defp google_client_secret do
    System.get_env("GOOGLE_CLIENT_SECRET") ||
      Application.get_env(:elixir_auth_google, :client_secret)
  end

  defp google_scope do
    System.get_env("GOOGLE_SCOPE") || Application.get_env(:elixir_auth_google, :google_scope) ||
      @default_scope
  end

  defp get_app_callback_url do
    System.get_env("GOOGLE_CALLBACK_PATH") ||
      Application.get_env(:elixir_auth_google, :callback_path) || @default_callback_path
  end
end
