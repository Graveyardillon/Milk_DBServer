defmodule Milk.AccountsBench do
  @moduledoc """
  Accounts.exの性能テスト
  """
  use Benchfella
  use Common.Fixtures

  alias Milk.Accounts

  setup_all do
    result = Application.ensure_all_started(:milk)
    1..128
    |> Enum.to_list()
    |> Enum.map(&fixture_user(num: &1))
    |> Enum.map(&Map.get(&1, :id))
    result
  end
  teardown_all _, do: Application.stop(:milk)

  bench "get_user" do
    1..128
    |> Enum.to_list()
    |> Enum.each(&Accounts.get_user(&1))
  end

  bench "load_user" do
    1..128
    |> Enum.to_list()
    |> Enum.each(&Accounts.load_user(&1))
  end
end
