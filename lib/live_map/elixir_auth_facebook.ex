defmodule ElixirAuthFacebook do
  @moduledoc """


  Get user access token
  <https://developers.facebook.com/docs/marketing-apis/overview/authentication/>
  """

  @default_callback_path "https://localhost:4443/auth/facebook/callback"
  @default_scope "public_profile"
  @auth_type "rerequest"
  @fb_dialog_oauth "https://www.facebook.com/v15.0/dialog/oauth?"
  @fb_access_token "https://graph.facebook.com/v15.0/oauth/access_token?"
  @fb_debug "https://graph.facebook.com/debug_token?"
  @fb_profile "https://graph.facebook.com/v15.0/me?fields=id,email,name,picture"
  @app_id System.get_env("FACEBOOK_APP_ID")
  @app_secret System.get_env("FACEBOOK_APP_SECRET")
  @app_access_token @app_id <> "|" <> @app_secret

  @doc """
  Generate URI for first access with temporary "code" from users' credentials.
  We also inject a "salt" to prevent CSRF and the APP_ID and we check if our "salt" is happily returned
  """
  def generate_oauth_url() do
    @fb_dialog_oauth <> params_1()
  end

  @doc """
  Generate URI for second query to exchange the "code" for an "access_token".
  The server generates the call and sends the APP_SECRET
  """
  defp get_access_token(code) do
    @fb_access_token <> params_2(code)
  end

  @doc """
  Third query to inspect Access Token
  """
  defp debug_token(token) do
    @fb_debug <> params_3(token)
  end

  @doc """
  Fetch user's profile with the Graph API.
  """
  defp graph_api(), do: @fb_profile

  @doc """
  Function to document how to terminate errors. Use flash, redirect...
  """
  def terminate(conn, message, path) do
    conn
    |> Phoenix.Controller.put_flash(:error, inspect(message))
    |> Phoenix.Controller.redirect(to: path)
    |> Plug.Conn.halt()
  end

  def handle_callback(conn, params, term \\ &terminate/3)

  def handle_callback(conn, %{"error" => error}, term) do
    term.(conn, error, "/")
  end

  @doc """
  We receive the "state" aka as "salt" we sent.
  """
  def handle_callback(conn, %{"state" => state, "code" => code} = params, term) do
    keys = Map.keys(params)

    with {:salt, true} <- {:salt, check_salt(state)},
         {:code, true} <- {:code, "code" in keys} do
      fb_oauth = get_access_token(code)

      case HTTPoison.get(fb_oauth) do
        {:error, %HTTPoison.Error{id: nil, reason: err}} ->
          term.(conn, err, "/")

        {:ok, %HTTPoison.Response{body: body}} ->
          case Jason.decode!(body) do
            %{"error" => %{"message" => message}} ->
              term.(conn, message, "/")

            body ->
              conn
              |> Plug.Conn.assign(:body, body)
              |> Plug.Conn.assign(:term, term)
              |> get_login()
              |> get_profile()
          end
      end
    else
      {:salt, false} ->
        term.(conn, "salt false", "/")

      {:code, false} ->
        term.(conn, "code false", "/")
    end
  end

  # def decode_body(conn, body) do
  #   Plug.Conn.assign(conn, :body, Jason.decode!(body))
  # end

  @doc """
  If user does not accept the Login dialog
  """

  def get_login(%Plug.Conn{assigns: %{body: %{"error" => %{"message" => message}}}} = conn) do
    conn.assigns.term.(conn, message, "/")
  end

  # curl -X GET "https://graph.facebook.com/oauth/access_token?client_id=366589421180047&client_secret=a7f31cd0acd223dd63af686842c3f224&grant_type=client_credentials"

  def get_login(%Plug.Conn{assigns: %{body: %{"access_token" => token}}} = conn) do
    term = conn.assigns.term

    case HTTPoison.get(debug_token(token)) do
      {:ok, %HTTPoison.Response{body: body}} ->
        case Jason.decode!(body) do
          %{"error" => %{"message" => message}} ->
            term.(conn, message, "/")

          %{"data" => data} ->
            %{"user_id" => fb_id, "is_valid" => valid, "expires_at" => exp} = data

            conn
            |> Plug.Conn.assign(:token, token)
            |> Plug.Conn.assign(:exp, exp)
            |> Plug.Conn.assign(:valid, valid)
            |> Plug.Conn.assign(:fb_id, fb_id)
        end

      {:error, %HTTPoison.Error{id: nil, reason: err}} ->
        term.(conn, err, "/")
    end
  end

  @doc """
  <https://developers.facebook.com/docs/graph-api/reference/user/>
  """

  def get_profile(%Plug.Conn{assigns: %{valid: false}} = conn) do
    conn.assigns.term.(conn, "renew your credentials", "/")
  end

  def get_profile(%Plug.Conn{assigns: %{token: token, exp: exp, valid: true}} = conn) do
    params = %{"access_token" => token} |> URI.encode_query()

    me_point = graph_api() <> "&" <> params
    term = conn.assigns.term

    case HTTPoison.get(me_point) do
      {:error, %HTTPoison.Error{id: nil, reason: err}} ->
        term.(conn, err, "/")

      {:ok, %HTTPoison.Response{body: body}} ->
        case Jason.decode!(body) do
          %{"error" => %{"message" => message}} ->
            term.(conn, message, "/")

          %{"email" => email, "id" => fb_id, "name" => name, "picture" => avatar} ->
            {:ok,
             %{
               email: email,
               fb_id: fb_id,
               name: name,
               avatar: avatar,
               exp: exp,
               token: token
             }}
        end
    end
  end

  def get_salt() do
    Application.get_env(:live_map, LiveMapWeb.Endpoint)
    |> List.keyfind(:live_view, 0)
    |> then(fn {:live_view, [signing_salt: val]} ->
      val
    end)
  end

  def check_salt(state) do
    get_salt() == state
  end

  defp params_1() do
    %{
      "client_id" => @app_id,
      "state" => get_salt(),
      "redirect_uri" => @default_callback_path,
      "scope" => @default_scope
    }
    |> URI.encode_query()
  end

  defp params_2(code) do
    %{
      "client_id" => @app_id,
      "state" => get_salt(),
      "redirect_uri" => @default_callback_path,
      "code" => code,
      "client_secret" => @app_secret
    }
    |> URI.encode_query()
  end

  defp params_3(token) do
    %{
      "access_token" => @app_access_token,
      "input_token" => token
    }
    |> URI.encode_query()
  end
end
