defmodule Milk.Tournaments.Rules do
  @moduledoc """
  大会で使用するルールに関するモジュール。
  """
  alias Common.Tools
  alias Milk.Tournaments
  alias Milk.Tournaments.Tournament
  alias Milk.Tournaments.Rules.{
    Basic,
    FlipBan
  }

  @spec adapt_keyname(integer()) :: String.t()
  def adapt_keyname(user_id), do: "user:#{user_id}"

  @doc """
  オートマトンの動作がredisに存在していなければ定義する
  """
  @spec initialize_state_machine(Tournament.t()) :: :ok | :error
  def initialize_state_machine(%Tournament{rule: rule, is_team: is_team}) do
    case rule do
      "basic"   -> Basic.define_dfa!(is_team: is_team)
      "flipban" -> FlipBan.define_dfa!(is_team: is_team)
      _         -> :error
    end
  end

  @doc """
  大会作成時に運営陣（master, assistant）のオートマトンを初期化する
  """
  @spec initialize_master_states(Tournament.t()) :: {:ok, nil}
  def initialize_master_states(%Tournament{id: tournament_id, rule: rule, is_team: is_team}) do
    tournament_id
    |> Tournaments.get_masters()
    |> Enum.map(fn user ->
      keyname = __MODULE__.adapt_keyname(user.id)

      case rule do
        "basic"   -> Basic.build_dfa_instance(keyname, is_team: is_team)
        "flipban" -> FlipBan.build_dfa_instance(keyname, is_team: is_team)
        _         -> raise "Invalid tournament rule"
      end
    end)
    |> Enum.all?(&(&1 == "OK"))
    |> Tools.boolean_to_tuple()
  end

  @spec start_master_states!(Tournament.t()) :: {:ok, Tournament.t()} | {:error, String.t()}
  def start_master_states!(tournament) do
    with {:ok, _}   <- start_master_state!(tournament),
         {:ok, nil} <- start_assistant_states!(tournament) do
      {:ok, tournament}
    else
      error -> error
    end
  end

  @spec start_master_state!(Tournament.t()) :: {:ok, any()} | {:error, String.t()}
  defp start_master_state!(%Tournament{id: tournament_id, rule: rule, master_id: master_id}) do
    tournament_id
    |> Tournaments.is_entrant?(master_id)
    |> if do
      {:ok, nil}
    else
      keyname = __MODULE__.adapt_keyname(master_id)

      case rule do
        "basic" -> Basic.trigger!(keyname, Basic.manager_trigger())
        "flipban" -> FlipBan.trigger!(keyname, FlipBan.manager_trigger())
        _ -> {:error, "Invalid tournament rule"}
      end
    end
  end

  @spec start_assistant_states!(Tournament.t()) :: {:ok, nil} | {:error, nil}
  defp start_assistant_states!(%Tournament{id: tournament_id, rule: rule}) do
    tournament_id
    |> Tournaments.get_assistants()
    |> Enum.map(fn assistant ->
      keyname = __MODULE__.adapt_keyname(assistant.user_id)

      case rule do
        "basic" -> Basic.trigger!(keyname, Basic.assistant_trigger())
        "flipban" -> FlipBan.trigger!(keyname, FlipBan.assistant_trigger())
      end
    end)
    |> Enum.all?(&match?({:ok, _}, &1))
    |> Tools.boolean_to_tuple()
  end
end
