defmodule MilkWeb.LoadTestController do
  use MilkWeb, :controller
  use Timex

  @log_file_path "load_test_log.txt"

  # TODO: 認証処理
  def start(conn, _) do
    pid_str =
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

    json(conn, %{result: true})
  end

  def crash(conn, _) do
    exit(:boom)
  end
end
