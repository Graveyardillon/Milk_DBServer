defmodule MilkWeb.ObanController do
    use MilkWeb, :controller

    def enqueue_job(conn, %{"tournament_id" => id}) do
        job = %{notify_tournament_start: id}
        |> Oban.Processer.new(schedule_in: 3)
        |> Oban.insert()
        |> elem(1)
        |> IO.inspect()
        
        result = if Map.get(job, :errors) |> length == 0, do: true, else: false
        id = Map.get(job, :id)
        json(conn, %{id: id, result: result})
        # id = %{}
        # |> Oban.TestWorker.new(schedule_in: 10)
        # |> Oban.insert()
        # |> IO.inspect()
        # |> elem(1)
        # |> Map.get(:id)

        # json(conn, %{result: true, msg: "enqueued", id: id})
    end
end