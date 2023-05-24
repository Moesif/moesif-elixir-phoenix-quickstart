defmodule MyApp.Router do
  use Phoenix.Router

  pipeline :api do
    plug :accepts, ["json"]
    plug MyApp.MoesifMiddleware
  end

  scope "/api", MyApp do
    pipe_through :api

    # Define your API routes here
  end

  # Other router configuration...
end
