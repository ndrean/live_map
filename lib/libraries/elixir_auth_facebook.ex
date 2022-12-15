defmodule Libraries.ElixirAuthFacebook do
  import Plug.Conn

  @moduledoc """
  This module exposes two functions to enable Facebook Login
  from the server

  - "generate_oauth_url" : takes the conn from the controller
  (to get the domain) and returns an URL with a query string.
  We reach Facebook with this URL.

  - "handle_callback": the callback of the endpoint that receives
  Facebook's response
  """

  @default_callback_path "/auth/facebook/callback"
  @default_scope "public_profile"
  @fb_dialog_oauth "https://www.facebook.com/v15.0/dialog/oauth?"
  @fb_access_token "https://graph.facebook.com/v15.0/oauth/access_token?"
  @fb_profile "https://graph.facebook.com/v15.0/me?fields=id,email,name,picture"

  # ------ APIs--------------
  @doc """
  Generates the url that opens Login dialogue.
  Receives the conn and delivers and URL
  """
  def generate_oauth_url(conn), do: @fb_dialog_oauth <> params_1(conn)

  @doc """
  Receives Facebook's payload and outputs the user's profile
  """
  # user denies dialog
  def handle_callback(_conn, %{"error" => message}) do
    {:error, {:access, message}}
  end

  def handle_callback(conn, %{"state" => state, "code" => code}) do
    case check_state(state) do
      false ->
        {:error, {:state, "Error with the state"}}

      true ->
        code
        |> access_token_uri(conn)
        |> decode_response()
        |> then(fn data ->
          conn
          |> assign(:data, data)
          |> get_profile()
          |> check_profile()
        end)
    end
  end

  def get_profile(%{assigns: %{data: %{"error" => %{"message" => message}}}}) do
    {:error, {:get_profile, message}}
  end

  def get_profile(%{assigns: %{data: %{"access_token" => token}}} = conn) do
    URI.encode_query(%{"access_token" => token})
    |> graph_api()
    |> decode_response()
    |> then(fn data ->
      assign(conn, :profile, data)
    end)
  end

  def check_profile({:error, message}), do: {:error, {:check_profile, message}}

  def check_profile(%{assigns: %{profile: %{"error" => %{"message" => message}}}}) do
    {:error, {:check_profile2, message}}
  end

  def check_profile(%{assigns: %{profile: profile}}) do
    profile =
      profile
      |> nice_map()
      |> exchange_id()

    {:ok, profile}
  end

  # ---------- Definition of the URLs

  @spec get_baseurl_from_conn(%{:host => any, optional(any) => any}) :: false | <<_::64, _::_*8>>
  def get_baseurl_from_conn(%{host: h, port: p}) when h == "localhost" do
    (p != 4000 && "https://localhost") || "http://" <> h <> ":#{p}"
  end

  def get_baseurl_from_conn(%{host: h}), do: "https://" <> h

  def generate_redirect_url(conn),
    do: get_baseurl_from_conn(conn) <> @default_callback_path

  # Generates the url for the exchange "code" to "access_token".
  def access_token_uri(code, conn), do: @fb_access_token <> params_2(code, conn)

  # Generates the Graph API url to query for users data.
  def graph_api(access), do: @fb_profile <> "&" <> access

  # ------ Private Helpers -------------

  # utility function: receives an url and provides the response body
  def decode_response(url) do
    url
    |> HTTPoison.get!()
    |> Map.get(:body)
    |> Jason.decode!()
  end

  # ---  cleaning the profile --------
  def into_atoms(strings) do
    for {k, v} <- strings, into: %{}, do: {String.to_atom(k), v}
  end

  # deep dive into the map
  def nice_map(map) do
    map
    |> into_atoms()
    |> Map.update!(:picture, fn pic ->
      pic["data"]
      |> into_atoms()
    end)
  end

  # FB gives and ID. We replace "id" to "fb_id"
  # to avoid confusion in the returned data
  def exchange_id(profile) do
    profile
    |> Map.put_new(:fb_id, profile.id)
    |> Map.delete(:id)
  end

  # ----- Helpers on state -------
  # verify that the received state is equal to the system state
  def check_state(state), do: get_state() == state

  # ----building query strings ------
  def params_1(conn) do
    URI.encode_query(
      %{
        "client_id" => app_id(),
        "state" => get_state(),
        "redirect_uri" => generate_redirect_url(conn),
        "scope" => @default_scope
      },
      :rfc3986
    )
  end

  def params_2(code, conn) do
    URI.encode_query(
      %{
        "client_id" => app_id(),
        "redirect_uri" => generate_redirect_url(conn),
        "code" => code,
        "client_secret" => app_secret()
      },
      :rfc3986
    )
  end

  # ---------- CREDENTIALS -----------
  def app_id() do
    System.get_env("FACEBOOK_APP_ID") ||
      Application.get_env(:elixir_auth_facebook, :fb_app_id)
  end

  def app_secret() do
    System.get_env("FACEBOOK_APP_SECRET") ||
      Application.get_env(:elixir_auth_facebook, :fb_app_secret)
  end

  #  anti-CSRF check
  def get_state() do
    System.get_env("FACEBOOK_STATE") ||
      Application.get_env(:elixir_auth_facebook, :app_state)
  end
end
