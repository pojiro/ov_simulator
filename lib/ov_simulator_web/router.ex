defmodule OvSimulatorWeb.Router do
  use OvSimulatorWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", OvSimulatorWeb do
    pipe_through :browser

    live "/", LiveMain
  end

  # Other scopes may use custom stacks.
  # scope "/api", OvSimulatorWeb do
  #   pipe_through :api
  # end
end
