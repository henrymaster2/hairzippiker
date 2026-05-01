defmodule HairZippikerWeb.ErrorJSONTest do
  use HairZippikerWeb.ConnCase, async: true

  test "renders 404" do
    assert HairZippikerWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert HairZippikerWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
