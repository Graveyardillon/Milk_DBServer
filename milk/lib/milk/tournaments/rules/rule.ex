defmodule Milk.Tournaments.Rules.Rule do
  @moduledoc """
  ルールに関するビヘイビアを実装するためのモジュール
  """
  alias Milk.Tournaments.Rules

  @doc """
  オートマトンの名前を返す関数
  """
  @callback machine_name(boolean()) :: String.t()

  @doc """
  オートマトンを定義するための関数
  """
  @callback define_dfa!(Rules.opts()) :: :ok

  @doc """
  オートマトンの型から新しいインスタンスを生成するための関数
  """
  @callback build_dfa_instance(String.t(), Rules.opts()) :: any()

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
  @callback list_states(Rules.list_state_opts()) :: [String.t()]
end
