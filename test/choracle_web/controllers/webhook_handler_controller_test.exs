defmodule ChoracleWeb.Controller.WebhookHandlerControllerTest do
  use ChoracleWeb.ConnCase, async: true

  alias ChoracleWeb.Controller.WebhookHandlerController
  alias Choracle.Factory

  @texts [
    "/create_roomie name:Mr. New,weekly_volume:1,weekend_volume:4",
    "/get_roomie_details name:Mr. Slacker",
    "/list_all_roomies",
    "/update_roomie name:Mr. Slacker,weekly_volume:2,weekend_volume:3",
    "/delete_roomie name:Mr. Slacker"
  ]

  setup do
    chat_id = 1111

    template = %{
      "message" => %{
        "chat" => %{
          "first_name" => "Filipe",
          "id" => chat_id,
          "last_name" => "Herculano",
          "type" => "private",
          "username" => "FilipeHerculoide"
        },
        "date" => 1_619_207_000,
        "entities" => [%{"length" => 17, "offset" => 0, "type" => "bot_command"}],
        "from" => %{
          "first_name" => "Filipe",
          "id" => 843_789_113,
          "is_bot" => false,
          "language_code" => "en",
          "last_name" => "Herculano",
          "username" => "FilipeHerculoide"
        },
        "message_id" => 381,
        "text" => ""
      },
      "update_id" => 452_698_411
    }

    ctx =
      :setup
      |> Factory.build!(chat_id)
      |> Map.put_new(:template, template)

    {:ok, ctx}
  end

  describe "handle/2" do
    Enum.each(
      @texts,
      &test "smoke with text: #{&1}", %{conn: conn, template: %{"message" => message} = template} do
        message = Map.put(message, "text", unquote(&1))
        param = Map.put(template, "message", message)
        WebhookHandlerController.handle(conn, param)
        # mock NADIA telegram receiving http response
      end
    )
  end
end
