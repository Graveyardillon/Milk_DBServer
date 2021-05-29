defmodule MilkWeb.LoadTestController do
  use MilkWeb, :controller
  use Timex

  alias Common.KeyValueStore

  @log_file_path "load_test_log.txt"

  # TODO: 認証処理
  def start(conn, _) do
    KeyValueStore.start()

    Task.async(fn ->
      start_count = 0
      count_up = 1
      sleep_msec = 1000

      @log_file_path
      |> File.exists?()
      |> if do
        File.write(@log_file_path, "")
      else
        File.touch(@log_file_path)
      end

      start_count
      |> Stream.iterate(&(&1 + count_up))
      |> Enum.map(fn _count ->
        {:ok, content} = File.read(@log_file_path)
        content = "#{content} \n #{:cpu_sup.util()} | #{Timex.now()}"
        File.write(@log_file_path, content)

        :timer.sleep(sleep_msec)
      end)
    end)
    |> Map.get(:pid)
    |> KeyValueStore.set(:load_test)

    json(conn, %{result: true})
  end

  def stop(conn, _) do
    KeyValueStore.get(:load_test)
    |> Process.exit(:boom)
    |> IO.inspect()

    json(conn, %{result: true})
  end

  def download(conn, _) do
    path = @log_file_path
    send_download(conn, {:file, path})
  end
end
