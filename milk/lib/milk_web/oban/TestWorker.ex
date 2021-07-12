defmodule Oban.TestWorker do
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id} = args}) do
    # model = MyApp.Repo.get(Milk.Business.Man, id)
    IO.puts("EXCUTED")
    IO.inspect(args, label: :args)

    case args do
      %{"in_the" => "business"} ->
        # IO.inspect(model)
        IO.inspect("business")

      %{"vote_for" => vote} ->
        # IO.inspect([vote, model])
        IO.inspect(vote)

      _ ->
        # IO.inspect(model)
        IO.puts("undefined")
    end

    :ok
  end
end