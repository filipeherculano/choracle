defmodule Choracle do
  @moduledoc """
  This module holds the business logic for Choracle bot and translates generic
  built Cmds to schema specific cmds.
  """

  alias Choracle.Parser.Roomie, as: RoomieParser
  alias Choracle.Repo
  alias Choracle.Repo.Manager.Roomie, as: RoomieManager
  alias Choracle.Repo.Roomie

  # TODO this should be removed in the future. Query logic must reamin in repo managers
  import Ecto.Query

  # NOTE If this module becames too large we could refactor it by removing the Cmd
  defmodule Cmd do
    @moduledoc false

    @type t :: %{
            args: list(any()) | nil,
            cmd: Roomie.crud() | nil,
            digest: RoomieParser.t(),
            response: any() | nil
          }

    defstruct args: nil,
              cmd: nil,
              digest: nil,
              response: nil
  end

  @type errors ::
          RoomieManager.errors()
          | {:error, :volumes_sum_must_equal_max_volume | :choracle_not_found}

  @spec run_cmd(Cmd.t()) :: {:ok, %Roomie{}} | errors()
  def run_cmd(%Cmd{digest: %RoomieParser{table_manager: table_manager}} = cmd_struct) do
    with {:ok, %Cmd{cmd: cmd, args: args} = cmd_struct} <- cmd_parse(cmd_struct),
         {:ok, response} <- apply(table_manager, cmd, args) do
      {:ok, %Cmd{cmd_struct | response: response}}
    else
      {:error, _} = error ->
        error
    end
  end

  defp cmd_parse(
         %Cmd{
           digest: %RoomieParser{
             cmd: :create,
             parsed_params: %RoomieParser.ParsedParams{
               chat_id: chat_id,
               name: name,
               weekend_volume: wknd,
               weekly_volume: wk
             }
           }
         } = cmd
       ) do
    # TODO use library once created, like:
    # max_volume = ChoracleManager.fetch_max_volume(chat_id)
    case Repo.all(from c in Repo.Choracle, where: [chat_id: ^chat_id]) do
      [%Repo.Choracle{max_volume: max_volume}] ->
        if max_volume == wk + wknd do
          {:ok, %Cmd{cmd | cmd: :insert, args: [chat_id, name, wk, wknd]}}
        else
          {:error, :volumes_sum_must_equal_max_volume}
        end

      [] ->
        {:error, :choracle_not_found}
    end
  end

  defp cmd_parse(
         %Cmd{
           digest: %RoomieParser{
             cmd: :read,
             parsed_params: %RoomieParser.ParsedParams{chat_id: chat_id},
             type: :all
           }
         } = cmd
       ) do
    {:ok, %Cmd{cmd | cmd: :get_all, args: [chat_id]}}
  end

  defp cmd_parse(
         %Cmd{
           digest: %RoomieParser{
             cmd: :read,
             parsed_params: %RoomieParser.ParsedParams{chat_id: chat_id, name: name},
             type: :one
           }
         } = cmd
       ) do
    {:ok, %Cmd{cmd | cmd: :get_one, args: [chat_id, name]}}
  end

  defp cmd_parse(
         %Cmd{
           digest: %RoomieParser{
             cmd: :update,
             parsed_params:
               %RoomieParser.ParsedParams{chat_id: chat_id, name: name} = parsed_params
           }
         } = cmd
       ) do
    # TODO use library once created, like:
    # max_volume = ChoracleManager.fetch_max_volume(chat_id)
    case Repo.all(from c in Repo.Choracle, where: [chat_id: ^chat_id]) do
      [%Repo.Choracle{max_volume: max_volume}] ->
        wk = Map.get(parsed_params, :weekly_volume)
        wknd = Map.get(parsed_params, :weekend_volume)

        params =
          %{weekly_volume: wk, weekend_volume: wknd}
          |> Enum.reject(fn {_k, v} -> is_nil(v) end)
          |> Enum.into(%{}, & &1)

        sum = params |> Map.values() |> Enum.sum()

        if sum == max_volume do
          {:ok, %Cmd{cmd | cmd: :update, args: [chat_id, name, params]}}
        else
          {:error, :volumes_sum_must_equal_max_volume}
        end

      [] ->
        {:error, :not_found}
    end
  end

  defp cmd_parse(
         %Cmd{
           digest: %RoomieParser{
             cmd: :delete,
             parsed_params: %RoomieParser.ParsedParams{chat_id: chat_id, name: name}
           }
         } = cmd
       ) do
    {:ok, %Cmd{cmd | cmd: :delete, args: [chat_id, name]}}
  end

  defp cmd_parse(_), do: {:error, :unknown_command}
end
