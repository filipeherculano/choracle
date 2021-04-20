defmodule ChoracleWeb.Controller.WebhookHandlerController do
  @moduledoc """
  This module handles Telegram POST resquests and redirects them to specific
  parsers only if the message follows the Choracle command protocol.
  """

  use ChoracleWeb, :controller

  import Plug.Conn

  alias Choracle.Parser.Roomie

  require Logger

  @help """
    > Hello,

    > My name is Choracle and I would like to introduce myself and explain stuff that I can do.

    > I can help you schedule cleaning routines by distributing volumes of chores on all roommates.

    > To start you must first call /init_choracle and provide the desired maximum. The maximum volume
    represents the volume within a weeks period of 7 days, given that 1 task = 1 volume.

    > After the step above you can start managing roomies and tasks and we do the rest for you.

    [not implemented] /init_choracle      - Begins choracle mediation.
    [not implemented] /set_maximum_volume - Sets maximum agreeable volume across all Roomies.
    [not implemented] /complete_task      - Records a complete Task

    [not implemented] /create_roomie      - Creates a new Roomie
    [not implemented] /get_roomie_details - Get details about a Roomie
    [not implemented] /list_all_roomies   - List all Roomies in this chat
    [not implemented] /update_roomie      - Update a Roomie
    [not implemented] /delete_roomie      - Delete a Roomie

    [not implemented] /create_task        - Creates a new Task
    [not implemented] /get_task_details   - Get details about a Task
    [not implemented] /list_all_tasks     - List all Task in this chat
    [not implemented] /update_task        - Update a Task
    [not implemented] /delete_task        - Delete a Task

    **WARNING**: This will erase all information for this chat (roomies, tasks, records, history).
    /kill_choracle - If you want to start all things over.

    For more information on each command format, try to calling it with /{command} help. Everyone
    in this chat has permissions to edit the choracle bot and also kill it.
  """

  # NOTE: Add any new parser here
  @parsers [Roomie]

  # NOTE: New parsers must implement those callbacks
  @callback commands() :: String.t()
  @callback handle_response({:ok, Choracle.Cmd.t()} | {:error, atom()}) :: String.t()
  @callback help() :: String.t()
  @callback parse(String.t(), non_neg_integer) :: {:ok, map()} | {:error, any()}

  def help(), do: @help

  # To be ignored by Cmd
  def parse(_, _), do: %Cmd{}

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

    check = fn text ->
      splitted = text |> String.split(" ")

      if length(splitted) > 1 do
        ["/" <> cmd | ["help" | _]] = splitted
        "/help #{cmd}"
      else
        text
      end
    end

    handle(conn, check.(text), chat_id)
  end

  def handle(conn, _params), do: ok(conn)

  defp handle(conn, "", chat_id),
    do:
      send_ok(
        "I'm sorry but this function is not supported or does not exist. For more information call /help",
        conn,
        chat_id
      )

  defp handle(conn, "/help" <> cmd, chat_id) do
    cmd
    |> String.replace(" ", "")
    |> find_parser()
    |> send_ok(conn, chat_id)
  end

  defp handle(conn, text, chat_id) do
    ["/" <> cmd | _] = String.split(text, " ")
    parser = find_parser(cmd)

    parser
    |> apply(:parse, [text, chat_id])
    |> Choracle.run_cmd()
    |> parser.handle_response()
    |> send_ok(conn, chat_id)
  end

  defp dispatch_cmd(%module{}, conn, text, chat_id) do
    text
    |> module.handle(chat_id)
    |> send_ok(conn, chat_id)
  end

  defp find_parser(cmd) do
    @parsers
    |> Enum.reduce(%{}, fn parser, acc -> parser.commands() |> Enum.into(%{}, &{&1, parser}) |> Map.merge(acc) end)
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
