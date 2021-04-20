defmodule Choracle do
  @moduledoc """
  This module holds the business logic for Choracle bot and translates generic
  built Cmds to schema specific cmds.
  """

  alias Choracle.Parser.Roomie, as: RoomieParser
  alias Choracle.Repo.Manager.Roomie, as: RoomieManager
  alias Choracle.Repo.Roomie

  # NOTE If this module becames too large we could refactor it by removing the Cmd
  defmodule Cmd do
    @moduledoc false

    @type crud :: :create | :read | :update | :delete
    @type t :: %{
            args: RoomieParser.t() | list(any()),
            cmd: crud() | RoomieManager.crud(),
            table_manager: RoomieManager,
            type: nil | :all | :get,
            response: any()
          }

    defstruct args: nil,
              cmd: nil,
              table_manager: nil,
              type: nil,
              response: nil
  end

  @spec run_cmd({:ok, Cmd.t()} | {:error, any()}) ::
          {:ok, %Roomie{}} | Roomie.errors() | {:error, :not_found}
  def run_cmd({:ok, %Cmd{table_manager: table_manager} = cmd_origin}) do
    %Cmd{cmd: cmd, args: args} = cmd_parse(cmd_origin)

    case apply(table_manager, cmd, args) do
      {:ok, response} ->
        {:ok, %{cmd_origin | response: response}}

      error ->
        error
    end
  end

  def run_cmd(error), do: error

  defp cmd_parse(
         %Cmd{
           table_manager: RoomieManager,
           cmd: :create,
           args: %{chat_id: chat_id, name: name, week_load: wk, weekend_load: wknd}
         } = cmd
       ) do
    %Cmd{cmd | cmd: :insert, args: [chat_id, name, wk, wknd]}
  end

  defp cmd_parse(%Cmd{table_manager: RoomieManager, cmd: :read, type: :all} = cmd) do
    %Cmd{cmd | cmd: :all, args: []}
  end

  defp cmd_parse(
         %Cmd{table_manager: RoomieManager, cmd: :read, type: :get, args: %{name: name}} = cmd
       ) do
    %Cmd{cmd | cmd: :get, args: [name]}
  end

  defp cmd_parse(%Cmd{table_manager: RoomieManager, cmd: :update, args: params} = cmd) do
    wk = params[:weekly_load]
    wknd = params[:weekend_load]

    params =
      %{weekly_load: wk, weekend_load: wknd}
      |> Enum.filter(fn {_k, v} -> is_nil(v) end)
      |> Enum.into(%{}, & &1)

    %Cmd{cmd | args: [params]}
  end

  defp cmd_parse(%Cmd{table_manager: RoomieManager, cmd: :delete, args: %{name: name}} = cmd) do
    %Cmd{cmd | args: [name]}
  end
end
