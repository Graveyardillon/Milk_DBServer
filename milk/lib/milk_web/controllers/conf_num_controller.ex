defmodule MilkWeb.ConfNumController do
  use MilkWeb, :controller
  import Bamboo.Email
  alias Milk.ConfNum

  def send_email(conn, %{"email" => email}) do
    number = :crypto.strong_rand_bytes(10) |> Base.encode32() |> binary_part(0, 10)
    new_email(
      to: email,
      from: "adhisuabeba@gmail.com",
      subject: "confirmation number",
      text_body: number
    )
    |> Milk.Mailer.deliver_now
    
    ConfNum.setConfNum(%{email => number})
    json(conn, %{result: true})
  end

  def conf_email(conn, %{"email" => email, "num" => num}) do
    number = 
      ConfNum.getConfNum() 
      |> Map.get(email)

    if(number == num) do
      ConfNum.deleteConfNum(email)
      json(conn, %{result: true})
    else
      json(conn, %{result: false})
    end
  end
end