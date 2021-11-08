defmodule Milk.Tournaments.Rules.Rule do
  @moduledoc """
  ルールに基づいて作動するオートマトンを定義するためのモジュール
  ルールのモジュールに依存する形で使われる。
  """
  @type opts :: [
    machine_name: String.t() | nil,
    is_team: boolean() | nil
  ]

  @type list_state_opts :: [
    is_team: boolean() | nil
  ]

  @doc """
  オートマトンを定義するredisデータベースのインデックスを決めるための関数
  """
  @spec db_index() :: integer()
  def db_index(), do: Application.get_env(:milk, :dfa_db_index)

  @doc """
  オートマトンの名前を返す関数
  """
  @callback machine_name(boolean()) :: String.t()

  @doc """
  オートマトンを定義するための関数
  """
  @callback define_dfa!(__MODULE__.opts()) :: :ok

  @doc """
  オートマトンの型から新しいインスタンスを生成するための関数
  """
  @callback build_dfa_instance(String.t(), __MODULE__.opts()) :: any()

  @doc """
  現在のオートマトン・インスタンスの状態を返す関数
  """
  @callback state!(String.t()) :: String.t()

  @doc """
  状態遷移のイベントを発火させるための関数
  """
  @callback trigger!(String.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}

  @doc """
  オートマトンの保持している状態一覧を返す関数
  """
  @callback list_states(__MODULE__.list_state_opts()) :: [String.t()]
end
