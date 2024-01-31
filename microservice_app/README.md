# MicroserviceApp

To build and start this example, you'll need to have Docker and Docker Compose installed.
Edit the `docker-compose.yml` file to set the `MOESIF_APPLICATION_ID` environment variable to your Moesif Application ID.

```
docker-compose up --build
```

## Configuration

You'll see an example of how to configure the Moesif API in the `runtime.exs` file. You can use the following configuration pattern to set up the Moesif API hooks.

Remember to set the `MOESIF_APPLICATION_ID` environment variable to your Moesif Application ID when running. The other request functions below are optional.

```elixir
config :moesif_api, :config,
  application_id: System.get_env("MOESIF_APPLICATION_ID"),
  get_user_id: fn(conn) ->
    case conn.query_params["user_id"] do
      nil -> nil
      user_id -> "user-#{user_id}"
    end
  end,
  get_company_id: fn(conn) ->
    case Plug.Conn.get_req_header(conn, "x-company-id") |> List.first do
      nil -> nil
      company_id -> "company-#{company_id}"
    end
  end,
  get_session_token: fn(conn) ->
    case Plug.Conn.get_req_header(conn, "x-session-token") |> List.first do
      nil -> nil
      token -> token
    end
  end,
  get_metadata: fn(_conn) -> %{"foo" => "bar"} end
```
