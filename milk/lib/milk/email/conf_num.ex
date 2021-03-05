defmodule Milk.ConfNum do
  use GenServer

  def init(_state) do 
    {:ok, %{}}
  end

  def start_link(state \\ %{}) do
    GenServer.start_link(__MODULE__ ,state, name: ConfNum)
  end

  def handle_call(:get, _from, state), do: {:reply, state, state}

  def handle_cast({:set, num}, state) do
    {:noreply, Map.merge(state, num)}
  end

  def handle_cast({:delete, email}, state), do: {:noreply, Map.delete(state, email)}

  def set_conf_num(num) do
    GenServer.cast(ConfNum, {:set, num})
  end

  def get_conf_num() do
    GenServer.call(ConfNum, :get)
  end

  def delete_conf_num(email) do
    GenServer.cast(ConfNum, {:delete, email})
  end
end
