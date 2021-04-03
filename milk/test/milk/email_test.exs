defmodule Milk.EmailTest do
  use ExUnit.Case

  alias Milk.Email

  test "hello email test" do
    email = "my@mail.com"
    return = Email.hello_email(email)

    assert return.to == email
    assert return.subject == "Welcome!"
    assert return.text_body =~ "Welcome to My App!!"
  end
end
