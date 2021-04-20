defmodule Choracle do
  @moduledoc """
  """

  use GenServer

  alias Choracle.Repo.Roomie
  alias Choracle.Repo.Manager.Roomie, as: RoomieManager

  defmodule Cmd do
    @type t :: %{}

    defstruct [
      :args,
      :cmd,
      :table_manager,
      :type,
      :response,
      :deferred_fn
    ]
  end

  def run_cmd(%{table_manager: table_manager} = cmd_origin) do
    %Cmd{cmd: cmd, args: args} = cmd_parse(cmd_origin)

    case apply(table_manager, cmd, args) do
      {:ok, response} ->
        {:ok, %{cmd_origin | response: response}}
      error -> error
    end
  end

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

  defp cmd_parse(
        %Cmd{table_manager: RoomieManager, cmd: :update, args: %{name: name} = params} = cmd
      ) do
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
