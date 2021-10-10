defmodule MilkWeb.CheckView do
  use MilkWeb, :view

  def render("check_for_web.json", %{unchecked_notification_exists: unchecked_notification_exists}) do
    %{
      result: true,
      unchecked_notification_exists: unchecked_notification_exists
    }
  end
end
