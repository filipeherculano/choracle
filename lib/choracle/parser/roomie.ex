defmodule Choracle.Parser.Roomie do
  alias Choracle.Cmd
  alias Choracle.Repo.Roomie
  alias Choracle.Repo.Manager.Roomie, as: RoomieManager
  alias ChoracleWeb.Controller.WebhookHandlerController

  @help """
  The following is the desired format for each message:

  /create_roomie name:"Filipe Herculano",weekly_volume:1,weekend_volume:2" *
  /get_roomie_details name:"Filipe Herculano"
  /list_all_roomies
  /update_roomie name:"Filipe Herculano"(,weekly_volume:2)(,weekend_volume:1) **
  /delete_roomie name:"Filipe Herculano"

  Maximum volume must be the amount of tasks you can tackle in a week. Weekly and weekend
  volume is the distribution of this value across the week. We know every person is different
  when it comes to getting things done around the house. That's why we try to ease this process
  by making you decide if you want to do more things during the week or the weekend. It's up
  to you!

  The only thing that matters is fairness. You need to agree with your Roomies the amount of
  chores every each one of you wants to do in a week's time with the /set_maximum_volume command.
  For more information try _/set_maximum_volume help_.

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
    :type,
    :weekend_volume,
    :weekly_volume
  ]

  @impl WebhookHandlerController
  def commands(), do: @commands

  @impl WebhookHandlerController
  def help(), do: @help

  @impl WebhookHandlerController
  defp parse(text, chat_id) do
    parse_params = fn text ->
      text
      |> String.replace("\"", "")
      |> String.split(",")
      |> Enum.into(%__MODULE__{}, fn
        "weekend_volume" <> _ ->
          {String.to_existing_atom(key), String.to_integer(value)}

        "weekly_volume" <> _ ->
          {String.to_existing_atom(key), String.to_integer(value)}

        str ->
          [key, value] = String.split(str, ":")
          {String.to_existing_atom(key), value}
      end)
    end

    cmd =
      cond text do
        "create_roomie " <> text ->
          %__MODULE__{name: name, weekly_volume: weekly_volume, weekend_volume: weekend_volume} =
            params = parse_params.(text)

          %Cmd{
            args: Map.put(params, :chat_id, chat_id),
            cmd: :create,
            table_manager: RoomieManager,
            type: nil
          }

        "get_roomie_details " <> text ->
          %Cmd{
            args: parse_params.(text),
            cmd: :read,
            table_manager: RoomieManager,
            type: :get
          }

        "list_all_roomies" <> text ->
          %Cmd{
            args: nil,
            cmd: :read,
            table_manager: RoomieManager,
            type: :all
          }

        "update_roomie " <> text ->
          %Cmd{
            args: parse_params.(text),
            cmd: :update,
            table_manager: RoomieManager,
            type: nil
          }

        "delete_roomie " <> text ->
          cmd = %Cmd{
            args: parse_params.(text),
            cmd: :delete,
            table_manager: RoomieManager,
            type: nil
          }
      end

    {:ok, cmd}
  rescue
    _ ->
      {:error, :wrong_format}
  end

  @impl WebhookHandlerController
  def handle_response({:error, _} = response), do: handle_error(response)
  def handle_response({:ok, _} = response), do: handle_success(response)

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
