defmodule OvSimulatorWeb.PageControllerTest do
  use OvSimulatorWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Optimal Velocity Model"
  end
end
