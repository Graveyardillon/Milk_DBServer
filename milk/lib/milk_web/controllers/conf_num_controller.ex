defmodule MilkWeb.ConfNumController do
  use MilkWeb, :controller

  import Bamboo.Email
  alias Milk.ConfNum
  alias Milk.Email.Auth
  alias Milk.Accounts

  @doc """
  Send an email for verification.
  FIXME: emailのexist確認
  """
  def send_email(conn, %{"email" => email}) do
    exists? = Accounts.is_email_exists?(email)

    if exists? do
      number =
        :rand.uniform(9999)
        |> Integer.to_string()
        |> String.pad_leading(4, "0")

      Task.start_link(fn ->
        new_email(
          to: email,
          from: "kunosoichiro@gmail.com",
          subject: "confirmation number",
          text_body: number
        )
        |> Milk.Mailer.deliver_now

        ConfNum.delete_conf_num(email)
        ConfNum.set_conf_num(%{email => number})
        Task.async(fn -> expire_conf_num(email) end)
      end)
    end

    json(conn, %{result: exists?})
  end

  defp expire_conf_num(email) do
    :timer.sleep(1000*60*10)
    ConfNum.delete_conf_num(email)
  end

  @doc """
  Verify email by sent number.
  """
  def conf_email(conn, %{"email" => email, "code" => code}) do
    number =
      ConfNum.get_conf_num()
      |> Map.get(email)

    if number == code do
      ConfNum.delete_conf_num(email)
      # ワンタイムパスワードの役割をするトークン
      token = publish_token_by_email(email)
      json(conn, %{result: true, token: token})
    else
      json(conn, %{result: false})
    end
  end

  defp publish_token_by_email(email) do
    token =
      :crypto.strong_rand_bytes(10)
      |> Base.encode32()
      |> binary_part(0, 10)

    Auth.set_token(%{email => token})
    token
  end
end
