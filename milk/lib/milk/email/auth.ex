defmodule Milk.Email.Auth do
  use GenServer

  def init(_state) do
    {:ok, %{}}
  end

  def start_link(state \\ %{}) do
    GenServer.start_link(__MODULE__, state, name: EmailAuth)
  end

  def handle_call(:get, _from, state), do: {:reply, state, state}

  def handle_cast({:set, token}, state) do
    {:noreply, Map.merge(state, token)}
  end

  def handle_cast({:delete, email}, state), do: {:noreply, Map.delete(state, email)}

  def set_token(token) do
    GenServer.cast(EmailAuth, {:set, token})
  end

  def get_token() do
    GenServer.call(EmailAuth, :get)
  end

  def delete_token(token) do
    GenServer.cast(EmailAuth, {:delete, token})
  end
end
