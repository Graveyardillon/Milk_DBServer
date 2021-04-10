defmodule Milk do
  @moduledoc """
  Milk keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.

  Program around TCP Server.
  It only connects Pappap Webserver.
  """

  alias Milk.Platforms

  def setup_platform() do
    Platforms.create_basic_platforms()
  end

  # TCP通信の部分とりあえずとっといてある
  # def accept(port) do
  #   {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :raw, active: false, reuseaddr: true])
  #   Logger.info("Accepting connections on port #{port}")
  #   loop_acceptor(socket)
  # end

  # defp loop_acceptor(socket) do
  #   {:ok, client} = :gen_tcp.accept(socket)
  #   Logger.info("TCP Client Connected")
  #   Task.start(fn -> serve(client) end)
  #   loop_acceptor(socket)
  # end

  # defp serve(socket) do
  #   socket
  #   |> read()
  #   |> String.replace(~r/\r|\n/, "")
  #   |> close_check(socket)
  #   |> process_by_sent_data(socket)

  #   serve(socket)
  # end

  # defp read(socket) do
  #   with {:ok, data} <- :gen_tcp.recv(socket, 0) do
  #     Logger.info(data)
  #     data
  #   else
  #     {:error, reason} -> reason
  #     _ -> "unexpected error on read"
  #   end
  # end

  # defp close_check("close", socket) do
  #   :gen_tcp.close(socket)
  #   Process.exit(Kernel.self(), :kill)
  # end
  # defp close_check(line, _socket), do: line

  # defp process_by_sent_data(data, socket) do
  #   case data do
  #     "user_sync" -> send_user_data(socket)
  #     _ -> do_nothing()
  #   end
  # end

  # defp send_user_data(socket) do
  #   Accounts.list_users()
  #   |> Enum.each(fn user ->
  #     id = Integer.to_string(user.id)
  #     Logger.info(id)
  #     :gen_tcp.send(socket, id)
  #     # sendの文字列が連結されちゃうからこうしたけど処理方法が絶対適切でない。
  #     :timer.sleep(1)
  #   end)
  # end

  # defp do_nothing() do
  #   # do nothing
  # end
end
