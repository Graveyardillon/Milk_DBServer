defprotocol Milk.Tournaments.Rules.Rule do
  @moduledoc """
  大会ルールに関する挙動は共通となる関数が多いので
  必要な処理を一致させるためのプロトコル
  """

  @spec machine_name(boolean()) :: String.t()
  def machine_name(is_team)

  @spec define_dfa!(Rules.opts()) :: :ok
  def define_dfa!(opts \\ [])

  @spec build_dfa_instance(String.t(), Rules.opts()) :: any()
  def build_dfa_instance(instance_name, opts \\ [])

  @spec state!(String.t()) :: String.t()
  def state!(instance_name)

  @spec trigger!(String.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def trigger!(instance_name, trigger)

  @spec list_states(Rules.list_state_opts()) :: [String.t()]
  def list_states(opts)
end
