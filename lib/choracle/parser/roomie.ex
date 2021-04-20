defmodule Choracle.Parser.Roomie do
  @moduledoc """
  Roomie parser implements WebhookHandlerController's behaviour and it is used
  for parsing Telegram's messages from users to Choracle.Cmd generic structure.

  Also handles all responses and translate them to a specific user friendly
  message that will be relayed to the user by our WebhookHandlerController.
  """

  alias Choracle.Cmd
  alias Choracle.Repo.Manager.Roomie, as: RoomieManager
  alias ChoracleWeb.Controller.WebhookHandlerController

  @help """
  The following is the desired format for each message:

  /create_roomie name:"Filipe Herculano",weekly_volume:1,weekend_volume:2" *
  /get_roomie_details name:"Filipe Herculano"
  /list_all_roomies
  /update_roomie name:"Filipe Herculano"(,weekly_volume:2)(,weekend_volume:1) **
  /delete_roomie name:"Filipe Herculano"

  Weekly and weekend volume is the distribution of maximum volume value across the week.
  We know every person is different when it comes to getting things done around the house.
  That's why we try to ease this process by making you decide if you want to do more things
  during the week or the weekend. It's up to you!

  The only thing that matters is fairness. You need to agree with your Roomies the amount of
  chores every each one of you wants to do in a week's time with the /init_choracle or
  /set_maximum_volume command.

  For more information try _/help_.

  * Weekly and weekend volume sum must be equal to the maximum volume agreed.
  ** Information inside parameters are optional
  """

  @behaviour WebhookHandlerController

  @commands [
    "create_roomie",
    "get_roomie_details",
    "list_all_roomies",
    "update_roomie",
    "delete_roomie"
  ]

  defstruct [
    :chat_id,
    :name,
    :weekend_volume,
    :weekly_volume
  ]

  @impl WebhookHandlerController
  def commands(), do: @commands

  @impl WebhookHandlerController
  def help(), do: @help

  @impl WebhookHandlerController
  def parse(text, chat_id) do
    parse_params = fn text ->
      text
      |> String.replace("\"", "")
      |> String.split(",")
      |> Enum.into(%__MODULE__{}, fn
        "weekend_volume:" <> value ->
          {:weekend_volume, String.to_integer(value)}

        "weekly_volume:" <> value ->
          {:weekly_volume, String.to_integer(value)}

        str ->
          [key, value] = String.split(str, ":")
          {String.to_existing_atom(key), value}
      end)
    end

    cmd =
      case text do
        "create_roomie " <> text ->
          text
          |> parse_params.()
          |> Map.put(:chat_id, chat_id)
          |> assemble_cmd(:create)

        "get_roomie_details " <> text ->
          assemble_cmd(parse_params.(text), :read, :get)

        "list_all_roomies" <> _text ->
          assemble_cmd(parse_params.(text), :read, :all)

        "update_roomie " <> text ->
          assemble_cmd(parse_params.(text), :update)

        "delete_roomie " <> text ->
          assemble_cmd(parse_params.(text), :delete)
      end

    {:ok, cmd}
  rescue
    _ ->
      {:error, :wrong_format}
  end

  @impl WebhookHandlerController
  def handle_response({:error, _} = response), do: handle_error(response)
  def handle_response({:ok, _} = response), do: handle_success(response)

  defp assemble_cmd(args, cmd, type \\ nil) do
    %Cmd{
      args: args,
      cmd: cmd,
      table_manager: RoomieManager,
      type: type
    }
  end

  defp handle_error({:error, :wrong_format}),
    do: "Wrong formatting, please run _/help_"

  defp handle_error({:error, :name_must_be_unique}),
    do: "Failed to run command. Name already taken"

  defp handle_error({:error, :name_length}), do: "Failed to run command. Name too long"

  defp handle_error({:error, :name_format}),
    do: "Failed to run command. Name must be only characters from A to Z."

  defp handle_error({:error, :out_of_range}),
    do: "Failed to run command. volume must be in between [1, 100]"

  defp handle_error({:error, :not_found}), do: "Failed to run command. Roomie not found"

  defp handle_success({:ok, %{cmd: :create, response: %{name: name}}}),
    do: "Roomie '#{name}' successfully created"

  defp handle_success(
         {:ok,
          %{
            cmd: :read,
            type: :get,
            response: %{name: name, weekly_volume: wk, weekend_volume: wknd}
          }}
       ),
       do: "name: #{name}, weekly_volume: #{wk}, weekend_volume: #{wknd}"

  defp handle_success({:ok, %{cmd: :read, type: :all, response: roomies}}),
    do: Enum.map(roomies, &"name: #{&1.name}\n")

  defp handle_success({:ok, %{cmd: :update, response: %{name: name}}}),
    do: "Roomie '#{name}' successfully updated"

  defp handle_success({:ok, %{cmd: :delete, response: %{name: name}}}),
    do: "Roomie '#{name}' successfully deleted"
end
