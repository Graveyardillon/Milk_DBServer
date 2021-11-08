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
  ルールに基づいて、大会作成用のフィールドを確認する
  """
  @spec validate_fields(map()) :: {:ok, map()} | {:error, String.t()}
  def validate_fields(fields) do
    case fields["rule"] do
      "flipban" -> validate_flipban_fields(fields)
      "basic" -> validate_basic_fields(fields)
      nil -> {:ok, fields}
      _ -> {:error, "Invalid tournament rule"}
    end
  end

  defp validate_basic_fields(attrs) do
    {:ok, attrs}
  end

  defp validate_flipban_fields(attrs) do
    {:ok, attrs}
  end

  @doc """
  大会作成時に
  """
  @spec initialize_master_states(Tournament.t()) :: {:ok, nil}
  def initialize_master_states(%Tournament{id: id, rule: rule, is_team: is_team}) do
    id
    |> Tournaments.get_masters()
    |> Enum.map(fn user ->
      keyname = __MODULE__.adapt_keyname(user.id)

      case rule do
        "basic" -> Basic.build_dfa_instance(keyname, is_team: is_team)
        "flipban" -> FlipBan.build_dfa_instance(keyname, is_team: is_team)
        _ -> raise "Invalid tournament rule"
      end
    end)
    |> Enum.all?(&(&1 == "OK"))
    |> Tools.boolean_to_tuple()
  end
end
