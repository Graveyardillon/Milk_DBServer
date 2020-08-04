defmodule Milk do
  @moduledoc """
  Milk keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.

  Program around TCP Server.
  It only connects Pappap Webserver.
  """
  require Logger

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :raw, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    Logger.info("TCP Client Connected")
    Task.start(fn -> serve(client) end)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    socket
    |> read_line()
    |> String.replace(~r/\r|\n/, "")
    |> close_check(socket)
    #|> write_line(socket)

    serve(socket)
  end

  defp read_line(socket) do
    with {:ok, data} <- :gen_tcp.recv(socket, 0) do
      Logger.info(data)
      data
    else
      {:error, reason} -> reason
      _ -> "unexpected error on read"
    end
  end

  defp close_check("close", socket) do
    :gen_tcp.close(socket)
    IO.inspect(Kernel.self)
    Process.exit(Kernel.self(), :kill)
  end
  defp close_check(line, _socket), do: line

  # defp write_line(line, socket) do
  #   Logger.info(line)
  #   :gen_tcp.send(socket, line)
  # end
end
