defmodule Choracle.Parser.Roomie do
  @moduledoc """
  Roomie parser implements WebhookHandlerController's behaviour and it is used
  for parsing Telegram's messages from users to Choracle.Cmd generic structure.

  Also handles all responses and translate them to a specific user friendly
  message that will be relayed to the user by our WebhookHandlerController.
  """

  alias Choracle.Repo.Manager.Roomie, as: RoomieManager
  alias ChoracleWeb.Controller.WebhookHandlerController

  require Logger

  @help """
  The following is the desired format for each message:

  /create_roomie name:Filipe Herculano,weekly_volume:1,weekend_volume:2*
  /get_roomie_details name:"Filipe Herculano"
  /list_all_roomies
  /update_roomie name:Filipe Herculano,weekly_volume:2,weekend_volume:1
  /delete_roomie name:Filipe Herculano

  Weekly and weekend volume is the distribution of maximum volume value across the week.\
  We know every person is different when it comes to getting things done around the house.\
  That's why we try to ease this process by making you decide if you want to do more things\
  during the week or the weekend. It's up to you!

  The only thing that matters is fairness. You need to agree with your Roomies the amount of\
  chores every each one of you wants to do in a week's time with the /init_choracle or \
  /set_maximum_volume command.

  For more information try /help.

  * Weekly and weekend volume sum must be equal to the maximum volume agreed.
  """

  @behaviour WebhookHandlerController

  @commands %{
    "create_roomie" => [:name, :weekend_volume, :weekly_volume],
    "get_roomie_details" => [:name],
    "list_all_roomies" => [],
    "update_roomie" => [:name, :weekend_volume, :weekly_volume],
    "delete_roomie" => [:name]
  }

  @type errors :: {:error, :wrong_format}
  @type crud :: :create | :read | :update | :delete
  @type t :: %{
          cmd: crud(),
          parsed_params: ParsedParams.t(),
          table_manager: __MODULE__,
          type: nil | :all | :one
        }

  defstruct cmd: nil,
            parsed_params: nil,
            table_manager: nil,
            type: nil

  defmodule ParsedParams do
    @moduledoc false
    @type t :: %{
            chat_id: integer(),
            name: String.t(),
            weekend_volume: integer() | nil,
            weekly_volume: integer() | nil
          }

    defstruct chat_id: nil,
              weekend_volume: nil,
              weekly_volume: nil,
              name: nil
  end

  @impl WebhookHandlerController
  def commands(), do: Map.keys(@commands)

  @impl WebhookHandlerController
  def help(), do: @help

  @impl WebhookHandlerController
  def parse(cmd, text_params, chat_id) do
    cmd_params = @commands[cmd]
    arity = length(cmd_params)
    parsed_params = parse_params(text_params, %ParsedParams{})

    # Raises if unmatching arity
    ^arity =
      parsed_params
      |> Map.take(cmd_params)
      |> Map.values()
      |> Enum.reject(&is_nil(&1))
      |> length()

    parsed_cmd =
      case cmd do
        "create_roomie" ->
          assemble_cmd(parsed_params, chat_id, :create)

        "get_roomie_details" ->
          assemble_cmd(parsed_params, chat_id, :read, :one)

        "list_all_roomies" ->
          assemble_cmd(parsed_params, chat_id, :read, :all)

        "update_roomie" ->
          assemble_cmd(parsed_params, chat_id, :update)

        "delete_roomie" ->
          assemble_cmd(parsed_params, chat_id, :delete)
      end

    {:ok, parsed_cmd}
  rescue
    _ ->
      {:error, :wrong_format}
  end

  @impl WebhookHandlerController
  def handle_response({:error, _} = response), do: handle_error(response)
  def handle_response({:ok, _} = response), do: handle_success(response)

  defp parse_params("", acc), do: cast_types(acc)

  defp parse_params(text_params, acc) do
    regex = ~r/([a-z_]*):([A-Za-z0-9\s\.]*)(,|$)/
    [matched, key, value, _comman_or_end] = Regex.run(regex, text_params)
    # Raises if key is named wrong
    acc = Map.put(acc, String.to_existing_atom(key), value)

    text_params
    |> String.replace(matched, "")
    |> parse_params(acc)
  end

  defp cast_types(
         %__MODULE__.ParsedParams{weekly_volume: wk, weekend_volume: wknd} = parsed_params
       )
       when is_nil(wk) or is_nil(wknd),
       do: parsed_params

  defp cast_types(
         %__MODULE__.ParsedParams{weekly_volume: wk, weekend_volume: wknd} = parsed_params
       ) do
    # Raises if value not a digit
    parsed_params
    |> Map.put(:weekly_volume, String.to_integer(wk))
    |> Map.put(:weekend_volume, String.to_integer(wknd))
  end

  defp assemble_cmd(parsed_params, chat_id, cmd, type \\ nil) do
    %__MODULE__{
      cmd: cmd,
      parsed_params: %ParsedParams{parsed_params | chat_id: chat_id},
      table_manager: RoomieManager,
      type: type
    }
  end

  # Repo validations
  defp handle_error({:error, :name_must_be_unique}),
    do: "Failed to run command. Name already taken in this chat"

  defp handle_error({:error, :name_length}), do: "Failed to run command. Name too long"

  defp handle_error({:error, :name_format}),
    do: "Failed to run command. Name must be only characters from A to Z."

  defp handle_error({:error, :out_of_range}),
    do: "Failed to run command. Volumes must be in between [1, 100]"

  # Manager validations
  defp handle_error({:error, :not_found}), do: "Failed to run command. Roomie not found"

  defp handle_error({:error, :choracle_not_found}),
    do: "Failed to run command. Choracle not initiated"

  # Choracle validations
  defp handle_error({:error, :volumes_sum_must_equal_max_volume}),
    do: "Failed to run command. Volumes sum must be equal to chat's maximum value"

  defp handle_success({:ok, %{cmd: :insert, response: %{name: name}}}),
    do: "Roomie '#{name}' successfully created!"

  defp handle_success(
         {:ok,
          %{
            cmd: :get_one,
            response: %{name: name, weekly_volume: wk, weekend_volume: wknd}
          }}
       ),
       do: "Roomie info name: #{name}, weekly_volume: #{wk}, weekend_volume: #{wknd}"

  defp handle_success({:ok, %{cmd: :get_all, response: roomies}}),
    do: roomies |> Enum.map(&"name: #{&1.name}") |> Enum.join("\n ")

  defp handle_success({:ok, %{cmd: :update, response: %{name: name}}}),
    do: "Roomie '#{name}' successfully updated!"

  defp handle_success({:ok, %{cmd: :delete, response: %{name: name}}}),
    do: "Roomie '#{name}' successfully deleted!"
end
