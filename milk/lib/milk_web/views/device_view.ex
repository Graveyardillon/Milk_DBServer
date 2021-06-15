defmodule MilkWeb.DeviceView do
  use MilkWeb, :view

  alias MilkWeb.DeviceView

  def render("show.json", %{device: device}) do
    %{
      result: true,
      data: render_one(device, DeviceView, "device.json")
    }
  end

  def render("device.json", %{device: device}) do
    %{
      id: device.id,
      token: device.token,
      user_id: device.user_id
    }
  end

  def render("error.json", %{error: error}) do
    if error do
      %{result: false, error: error, data: nil}
    else
      %{result: false, error: nil, data: nil}
    end
  end
end
