defmodule HackscraperWeb.ErrorJSONTest do
  use HackscraperWeb.ConnCase, async: true

  test "renders 404" do
    assert HackscraperWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert HackscraperWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
