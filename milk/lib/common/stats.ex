defmodule Common.Stats do
  defmacro __using__(_opts) do
    quote do
      def create_statistics(create_times) do
        case length(create_times) do
          0 -> %{}
          1 -> [head] = create_times
          create_statistics(%{head => 1}, [])
          _ -> [head|tail] = create_times
          create_statistics(%{head => 1}, tail)
        end

      end
     defp create_statistics(result, []) do
        result
     end
      defp create_statistics(result, remain) do
        [head|tail] = remain
        case Map.get(result, head) do
          nil -> Map.put(result, head, 1)
          _   -> Map.update!(result, head, fn v -> v + 1 end)
        end
        |> create_statistics(tail)
      end
    end
  end
end
