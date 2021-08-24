defmodule MilkWeb.ExternalServiceView do
  use MilkWeb, :view

  alias MilkWeb.ExternalServiceView

  def render("show.json", %{external_service: external_service}) do
    %{
      data: render_one(external_service, ExternalServiceView, "external_service.json"),
      result: true
    }
  end

  def render("external_service.json", %{external_service: external_service}) do
    %{
      id: external_service.id,
      name: external_service.name,
      content: external_service.content
    }
  end
end
