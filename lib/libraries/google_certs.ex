defmodule Libraries.ElixirGoogleCerts do
  @g_certs3_url "https://www.googleapis.com/oauth2/v3/certs"
  @iss "https://accounts.google.com"
  # @aud System.get_env("GOOGLE_CLIENT_ID")

  def verified_identity(jwt) do
    with {:ok,
          %{
            "aud" => aud,
            "azp" => azp,
            "email" => email,
            "iss" => iss,
            "name" => name,
            "picture" => pic,
            "sub" => sub
          }} <- check_identity(jwt),
         true <- check_user(aud, azp),
         true <- check_iss(iss) do
      {:ok, %{email: email, name: name, google_id: sub, picture: pic}}
    else
      {:error, message} -> {:error, message}
      false -> {:error, false}
    end
  end

  def check_identity(jwt) do
    with {:ok, %{"kid" => kid, "alg" => alg}} <- Joken.peek_header(jwt) do
      %{"keys" => certs} =
        @g_certs3_url
        |> HTTPoison.get!()
        |> Map.get(:body)
        |> Jason.decode!()

      cert = Enum.find(certs, fn cert -> cert["kid"] == kid end)
      signer = Joken.Signer.create(alg, cert)
      Joken.verify(jwt, signer, [])
    else
      {:error, message} -> {:error, message}
    end
  end

  def check_user(aud, azp) do
    aud == aud() || azp == aud()
  end

  def check_iss(iss), do: iss == @iss
  def aud, do: System.get_env("GOOGLE_CLIENT_ID")
end
