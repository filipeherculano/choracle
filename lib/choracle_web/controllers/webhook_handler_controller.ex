defmodule ChoracleWeb.Controller.WebhookHandlerController do
  @moduledoc """
  This module handles Telegram POST resquests and redirects them to specific
  controllers only if the message follows the Choracle command protocol.
  """

  use ChoracleWeb, :controller

  import Plug.Conn

  alias ChoracleWeb.Controller.RoomieController

  require Logger

  @help """
    Hello, my name is Choracle and I would like to introduce myself and stuff I can do for you. I can help you schedule cleaning routines by distributing loads of chores on all roommates.

    * Manage Roomies *
    /create_roomie - Creates a new Roomie
    /get_roomie_details - Get details about a Roomie [not implemented yet]
    /list_all_roomies - List all Roomies in this chat
    /update_roomie - Update a Roomie [not implemented yet]
    /delete_roomie - Delete a Roomie

    *Manage Areas* [not implemented yet]
    /create_area - Creates a new Area
    /get_area_details - Get details about a Area
    /list_all_areas - List all Areas in this chat
    /update_area - Update a Area
    /delete_area - Delete a Area

    *Manage Tasks* [not implemented yet]
    /create_task - Creates a new Task
    /get_task_details - Get details about a Task
    /list_all_tasks - List all Task in this chat
    /update_task - Update a Task
    /delete_task - Delete a Task

    *Register Completed Tasks* [not implemented yet]
    /set_maximum_load - Sets maximum agreeable load across Roomies
    /record_task - Records a complete Task

    For more information on each command format, try to calling it with /{command} help
  """

  # NOTE: Add any new controller here
  @controllers [RoomieController]

  # NOTE: New controllers must implement those callbacks
  @callback commands() :: String.t()
  @callback help() :: String.t()
  @callback handle(String.t()) :: String.t()

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
    |> find_controller()
    |> send_help(conn, chat_id)
  end

  defp handle(conn, text, chat_id) do
    ["/" <> cmd | _] = String.split(text, " ")

    cmd
    |> find_controller()
    |> run_cmd(conn, text, chat_id)
    |> send_ok(conn, chat_id)
  end

  defp run_cmd(__MODULE__, conn, _text, chat_id), do: __MODULE__.handle(conn, "", chat_id)

  defp run_cmd(module, conn, text, chat_id) do
    text
    |> module.handle()
    |> send_ok(conn, chat_id)
  end

  defp find_controller(cmd) do
    @controllers
    |> Enum.into(%{}, &Enum.map(&1.commands(), %{}, fn cmd -> {cmd, &1} end))
    |> Map.get(cmd)
    |> case do
      nil ->
        __MODULE__

      mod ->
        mod
    end
  end

  defp help(), do: @help

  defp send_help(module, conn, chat_id) do
    Nadia.send_message(chat_id, module.help())

    ok(conn)
  end

  def send_ok(response, conn, chat_id) do
    Nadia.send_message(chat_id, response)

    ok(conn)
  end

  defp ok(conn) do
    conn
    |> put_status(:ok)
    |> send_resp(200, "")
  end
end
