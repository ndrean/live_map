defmodule ElixirAuthFacebookTest do
  use ExUnit.Case, async: true

  test "credentials & config" do
    env_app_id = System.get_env("FACEBOOK_APP_ID")
    config_app_id = Application.get_env(:elixir_auth_facebook, :app_id)

    assert env_app_id == config_app_id
    assert env_app_id == ElixirAuthFacebook.app_id()

    env_app_secret = System.get_env("FACEBOOK_APP_SECRET")
    config_app_secret = Application.get_env(:elixir_auth_facebook, :app_secret)

    assert env_app_secret == config_app_secret
    assert env_app_secret == ElixirAuthFacebook.app_secret()

    app_access_token = env_app_id <> "|" <> env_app_secret

    assert ElixirAuthFacebook.app_access_token() == app_access_token
  end

  test "redirect_urls" do
    conn = %Plug.Conn{host: "localhost"}
    callback_url = "/auth/facebook/callback"

    if System.get_env("FACEBOOK_HTTPS") == "true" do
      https = "https://localhost"
      assert ElixirAuthFacebook.generate_redirect_url(conn) == https <> callback_url
    else
      http = "http://localhost:4000"
      assert ElixirAuthFacebook.generate_redirect_url(conn) == http <> callback_url
    end

    conn = %Plug.Conn{scheme: :https, host: "dwyl.com"}

    assert ElixirAuthFacebook.generate_redirect_url(conn) ==
             "https://dwyl.com" <> callback_url
  end

  test "state" do
    state = System.get_env("FACEBOOK_STATE")
    assert ElixirAuthFacebook.get_state() == state
    assert ElixirAuthFacebook.check_state(state) == true

    state = "123"
    assert ElixirAuthFacebook.check_state(state) == false
  end

  test "build params" do
    conn = %Plug.Conn{scheme: :https, host: "dwyl.com"}

    expected =
      "client_id=654166006222741&redirect_uri=https%3A%2F%2Fdwyl.com%2Fauth%2Ffacebook%2Fcallback&scope=public_profile&state=g0TzQq6hHAEDbvdqxLU8ltfVin%2BN6528"

    assert ElixirAuthFacebook.params_1(conn) == expected

    expected =
      "access_token=#{ElixirAuthFacebook.app_id()}%7C#{ElixirAuthFacebook.app_secret()}&input_token=aze"

    assert ElixirAuthFacebook.params_3("aze") == expected
  end

  test "exchange_id" do
    profile = %{id: 1}
    assert ElixirAuthFacebook.exchange_id(profile) == %{fb_id: 1}
  end

  test "get response body from url" do
    url = "dwyl.com"
  end

  test "check_profile" do
    profile = %{"a" => 1, "b" => 2, "id" => 12, "picture" => %{"data" => %{"url" => 3}}}
    expected = %{a: 1, b: 2, id: 12, picture: %{"data" => %{"url" => 3}}}
    assert ElixirAuthFacebook.into_atoms(profile) == expected

    expected = %{a: 1, b: 2, id: 12, picture: %{url: 3}}
    assert ElixirAuthFacebook.nice_map(profile) == expected

    conn = %Plug.Conn{
      assigns: %{access_token: "token", profile: profile}
    }

    res = %{access_token: "token", a: 1, b: 2, fb_id: 12, picture: %{url: 3}}
    assert ElixirAuthFacebook.check_profile(conn) == {:ok, res}
  end

  test "get_profile_err" do
    conn = %Plug.Conn{assigns: %{access_token: "token", is_valid: true}}
    res = %{conn | assigns: Map.put_new(conn.assigns, :profile, "data")}

    assert ElixirAuthFacebook.get_profile(conn).assigns.profile["error"]["message"] ==
             "Invalid OAuth access token - Cannot parse access token"
  end

  test "get_data detects wrong token" do
    conn = %Plug.Conn{assigns: %{data: %{"access_token" => "token"}}}

    assert ElixirAuthFacebook.get_data(conn).assigns.data["is_valid"] == nil
  end

  test "captures errors" do
    conn = %Plug.Conn{assigns: %{data: %{"error" => %{"message" => "test"}}}}
    assert ElixirAuthFacebook.get_data({:error, "test"}) == {:error, {:get_data, "test"}}
    assert ElixirAuthFacebook.get_data(conn) == {:error, {:get_data, "test"}}

    assert ElixirAuthFacebook.check_profile({:error, "test"}) ==
             {:error, {:check_profile, "test"}}

    assert ElixirAuthFacebook.check_profile(conn) == {:error, {:check_profile, "test"}}

    assert ElixirAuthFacebook.get_profile({:error, "test"}) ==
             {:error, {:get_profile, "test"}}

    conn = %Plug.Conn{assigns: %{is_valid: nil}}

    assert ElixirAuthFacebook.get_profile(conn) ==
             {:error, {:get_profile, "renew your credentials"}}
  end

  test "bad app_secret" do
    conn = %Plug.Conn{}
    assert ElixirAuthFacebook.get_data(conn) == "ok"
    # {:get_data, "Error validating client secret."}
  end

  def term_test(conn, _msg, _pth), do: conn

  test "decode_reponse" do
    url = "https://jsonplaceholder.typicode.com/todos/1"
    assert ElixirAuthFacebook.decode_response(url)["id"] == 1
  end

  test "handle" do
    assert ElixirAuthFacebook.handle_callback(
             %Plug.Conn{},
             %{"error" => "ok"}
           ) == {:error, {:access, "ok"}}
  end
end
