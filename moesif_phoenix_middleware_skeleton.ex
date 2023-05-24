defmodule MyApp.MoesifMiddleware do
  @behaviour Phoenix.Router.Middleware

  def init(opts), do: opts

  def call(conn, _opts) do
    request_start_time = DateTime.from_unix(request_start_time / 1000, "Z")
    {conn, req_body_stream} = capture_request_body(conn)
    conn = log_request(conn, req_body_stream, request_start_time)
    conn = log_response(conn, request_start_time)
    conn
  end

  defp capture_request_body(conn) do
    case Plug.Conn.read_body(conn) do
      {:ok, req_body, req_body_stream} ->
        conn = Plug.Conn.put_req_body(conn, req_body)
        {conn, req_body_stream}
      _ ->
        {conn, nil}
    end
  end

  defp log_request(conn, req_body_stream, request_start_time) do
    conn = conn
      |> store_request_data(req_body_stream, request_start_time)
      |> Plug.Conn.put_resp_header("X-Capture-Request-Data", "true")
    conn
  end

  defp store_request_data(conn, req_body_stream, request_start_time) do
    conn
    |> put_in_session(:request_data, %{
      method: conn.method,
      url: conn.request_url,
      headers: conn.req_headers,
      body: req_body_stream,
      request_start_time: request_start_time
      request_ip: Plug.Conn.get_remote_ip(conn)
    })
  end

  defp log_response(conn, request_start_time) do
    conn = conn
      |> Plug.Conn.register_before_send(send_request_data_to_moesif(request_start_time))
      |> Plug.Conn.delete_session(:request_data)
    conn
  end

  defp send_request_data_to_moesif(request_start_time) do
    fn(conn) ->
      case get_session(conn, :request_data) do
        %{
          method: method,
          url: url,
          headers: headers,
          body: body,
          request_start_time: request_start_time,
          request_id: request_ip
        } ->
          response_end_time = DateTime.from_unix(request_start_time / 1000, "Z")
          request_duration = response_end_time - request_start_time

          send_data_to_moesif(method, url, headers, body, conn.resp_body, conn.status, request_start_time, request_end_time, request_ip)

        _ ->
          IO.puts("Failed to retrieve request data from session.")
      end
      conn
    end
  end

  defp send_data_to_moesif(method, url, headers, body, response_body, response_status, request_start_time, request_end_time, request_ip) do
    # Perform the API call to Moesif here
    # Use your preferred HTTP client library and replace the placeholders with the actual endpoint and headers

    endpoint = "https://api.moesif.net/v1/events/batch"
    headers = [
      {"Content-Type", "application/json"},
      {"X-Moesif-Application-Id", "Your Moesif Application Id"}
    ]

    payload = [
        %{
          request: %{
            time: request_start_time,
            verb: method,
            uri: url,
            ip_address: request_ip,
            headers: headers,
            body: body,
            time: request_duration
          },
          response: %{
            time: request_end_time,
            status: response_status,
            headers: conn.resp_headers,
            body: response_body,
            time: request_duration
          }
        }
      ]


    case HTTPoison.post(endpoint, payload, headers) do
      {:ok, _response} ->
        IO.puts "Log sent to Moesif"
      {:error, reason} ->
        IO.puts "Failed to send log to Moesif: #{inspect(reason)}"
    end
  end
end
