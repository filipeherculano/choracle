defmodule ChoracleWeb.Controller.WebhookHandlerController do
  @moduledoc """
  This module handles Telegram POST resquests and redirects them to specific
  parsers only if the message follows the Choracle.Cmd structure.

  In order to ease parsers creation we must follow the WebhookHandlerController
  behaviour. With it, the parses can be used to create cmds and send them to our
  main module.
  """

  use ChoracleWeb, :controller

  import Plug.Conn

  alias Choracle.Parser.Roomie, as: RoomieParser
  alias Choracle.Repo.Roomie

  require Logger

  @help """
    Hello, My name is Choracle and I would like to introduce myself and explain stuff that I can do. \
    I can help you schedule cleaning routines by distributing volumes of chores on all roommates. To start \
    you must first call /init_choracle and provide the desired maximum. The maximum volume represents the \
    volume within a weeks period of 7 days, given that 1 task = 1 volume. After the step above you can start \
    managing roomies and tasks and we do the rest for you.

    [TBI] /init_choracle      - Begins choracle mediation.
    [TBI] /set_maximum_volume - Sets maximum agreeable volume across all Roomies.
    [TBI] /complete_task      - Records a complete Task

    [BETA] /create_roomie      - Creates a new Roomie
    [BETA] /get_roomie_details - Get details about a Roomie
    [BETA] /list_all_roomies   - List all Roomies in this chat
    [BETA] /update_roomie      - Update a Roomie
    [BETA] /delete_roomie      - Delete a Roomie

    [TBI] /create_task        - Creates a new Task
    [TBI] /get_task_details   - Get details about a Task
    [TBI] /list_all_tasks     - List all Task in this chat
    [TBI] /update_task        - Update a Task
    [TBI] /delete_task        - Delete a Task

    **WARNING**: This will erase all information for this chat (roomies, tasks, records, history).
    [TBI] /kill_choracle - If you want to start all things over.

    For more information on each command format, try to calling it with /{command} help. Everyone
    in this chat has permissions to edit the choracle bot and also kill it.
  """

  # NOTE: Add any new parser here
  @parsers [RoomieParser]

  # NOTE: New parsers must implement those callbacks
  @callback commands() :: list(String.t())
  @callback handle_response({:ok, %Roomie{}} | Roomie.errors() | {:error, :not_found}) ::
              String.t()
  @callback help() :: String.t()
  @callback parse(String.t(), String.t(), non_neg_integer) :: {:ok, Choracle.Cmd.t()} | RoomieParser.error()

  def help(), do: @help
  def parse(_, _, _), do: {:ok, :help}

  def handle(
        conn,
        %{
          "message" => %{
            "chat" => %{"id" => chat_id},
            "entities" => [%{"type" => "bot_command"}],
            "from" => %{"first_name" => first_name, "is_bot" => false, "last_name" => last_name},
            "text" => text
          }
        }
      ) do
    Logger.info("Received command from #{first_name} #{last_name} on chat #{chat_id}")

    ["/" <> cmd | params] = text |> String.split(" ", parts: 2)
    params = List.first(params) || ""
    parser = find_parser(cmd)

    input =
      cmd
      |> parser.parse(params, chat_id)
      |> case do
        {:ok, :help} ->
          ["help", %{}]

        {:ok, parsed_cmd} ->
          [cmd, parsed_cmd]

        {:error, :wrong_format} ->
          ["help", cmd]
      end

    handle(conn, input, parser, chat_id)
  end

  def handle(conn, _params), do: ok(conn)

  defp handle(conn, ["help",  _], parser, chat_id), do: send_ok(parser, conn, chat_id)

  defp handle(conn, [_cmd, parsed_cmd], parser, chat_id) do
    Choracle.Cmd
    |> struct()
    |> Map.put(:digest, parsed_cmd)
    |> Choracle.run_cmd()
    |> parser.handle_response()
    |> send_ok(conn, chat_id)
  end

  defp find_parser(cmd) do
    @parsers
    |> Enum.reduce(%{}, fn parser, acc ->
      parser.commands() |> Enum.into(%{}, &{&1, parser}) |> Map.merge(acc)
    end)
    |> Map.get(cmd)
    |> case do
      nil ->
        __MODULE__

      mod ->
        mod
    end
  end

  defp send_ok(response, conn, chat_id) when is_binary(response) do
    Nadia.send_message(chat_id, response)

    ok(conn)
  end

  defp send_ok(module, conn, chat_id) do
    Nadia.send_message(chat_id, module.help())

    ok(conn)
  end

  defp ok(conn) do
    conn
    |> put_status(:ok)
    |> send_resp(200, "")
  end
end
