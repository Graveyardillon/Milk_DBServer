defmodule Milk.Email do
  import Bamboo.Email

  def hello_email(email) do
    new_email(
      to: email,
      from: "mikan.kkmk@gmail.com",
      subject: "Welcome!",
      text_body: "Welcome to My App!!"
    )
  end
end
