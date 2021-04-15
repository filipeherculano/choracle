defmodule ChoracleWeb.Controller.RoomieController do
  use ChoracleWeb, :controller

  alias Choracle.Roomies
  alias Choracle.Repo.Roomie
  alias ChoracleWeb.Controller.WebhookHandlerController

  @help """
  The following is the desired format for each message:

  /create_roomie name:"Filipe Herculano",weekly_load:1,weekend_load:2" *
  /get_roomie_details name:"Filipe Herculano"
  /list_all_roomies
  /update_roomie name:"Filipe Herculano"(,weekly_load:2)(,weekend_load:1) **
  /delete_roomie name:"Filipe Herculano"

  Maximum load must be the amount of tasks you can tackle in a week. Weekly and weekend
  load is the distribution of this value across the week. We know every person is different
  when it comes to getting things done around the house. That's why we try to ease this process
  by making you decide if you want to do more things during the week or the weekend. It's up
  to you!

  The only thing that matters is fairness. You need to agree with your Roomies the amount of
  chores every each one of you wants to do in a week's time with the /set_maximum_load command.
  For more information try _/set_maximum_load help_.

  * Weekly and weekend loads sum must be equal to the maximum load agreed.
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

  @defstruct [
    :name,
    :weekly_load,
    :weekend_load,
    :type
  ]

  @impl WebhookHandlerController
  def commands(), do: @commands

  @impl WebhookHandlerController
  def help(), do: @help

  @impl WebhookHandlerController
  def handle("/create_roomie " <> text) do
    case parse(text) do
      {:ok, %{name: name, week_load: wk, weekend_load: wknd}} ->
        wk = String.to_integer(wk)
        wknd = String.to_integer(wknd)

        name
        |> Roomies.insert(wk, wknd)
        |> case do
          {:ok, _} ->
            "Roomie '#{name}' successfully created"

          error ->
            handle_error(error)
        end

      error ->
        handle_error(error)
    end
  end

  def handle("/get_roomie_details " <> text) do
    case parse(text) do
      {:ok, %{name: name}} ->
        case Roomies.get(name) do
          {:ok, %Roomie{name: name, weekly_volume: wk, weekend_volume: wknd}} ->
            "name: #{name}, weekly_volume: #{wk}, weekend_volume: #{wknd}"

          error ->
            error
        end

      error ->
        handle_error(error)
    end
  end

  def handle("/list_all_roomies" <> _) do
    Roomies.all()
    |> Enum.map(fn %Roomie{name: name} -> "name: #{name}" end)
    |> Enum.join("\n")
  end

  def handle("/update_roomie " <> text) do
    case parse(text) do
      {:ok, %{name: name} = params} ->
        wk = params[:weekly_load]
        wknd = params[:weekend_load]

        params =
          %{week_load: wk, weekend_load: wknd}
          |> Enum.filter(fn {_k, v} -> is_nil(v) end)
          |> Enum.into(%{}, & &1)

        case Roomies.update(name, params) do
          {:ok, _} ->
            "Roomie '#{name}' successfully updated"

          error ->
            error
        end

      error ->
        handle_error(error)
    end
  end

  def handle("/delete_roomie " <> text) do
    case parse(text) do
      {:ok, %{name: name}} ->
        name
        |> Roomies.delete()
        |> case do
          {:ok, _} ->
            "Roomie '#{name}' successfully deleted"

          error ->
            error
        end

      error ->
        handle_error(error)
    end
  end

  defp parse(text) do
    params =
      text
      |> String.replace("\"", "")
      |> String.split(",")
      |> Enum.into(%{}, fn str ->
        [key, value] = String.split(str, ":")
        {String.to_existing_atom(key), value}
      end)

    {:ok, params}
  rescue
    _ ->
      {:error, :wrong_format}
  end

  defp handle_error({:error, :wrong_format}),
    do: "Wrong formatting, please run _/help_"

  defp handle_error({:error, :sum_not_equal}),
    do: "Failed to run command. Sum of week and weekend load must be equal to maximum load"

  defp handle_error({:error, :name_must_be_unique}),
    do: "Failed to run command. Name already taken"

  defp handle_error({:error, :name_length}), do: "Failed to run command. Name too long"

  defp handle_error({:error, :name_format}),
    do: "Failed to run command. Name must be only characters from A to Z."

  defp handle_error({:error, :out_of_range}),
    do: "Failed to run command. Loads must be in between [1, 100]"

  defp handle_error({:error, :not_found}), do: "Failed to run command. Roomie not found"
end
