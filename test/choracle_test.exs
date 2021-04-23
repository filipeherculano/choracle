defmodule ChoracleTest do
  use ExUnit.Case, async: true

  alias Choracle.Cmd
  alias Choracle.Factory
  alias Choracle.Parser.Roomie, as: RoomieParser
  alias Choracle.Repo
  alias Choracle.Repo.Manager.Roomie, as: RoomieManager
  alias Choracle.Repo.Roomie

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    {:ok, Factory.build!(:setup)}
  end

  describe "run_cmd/1" do
    test "create roomie", %{
      mr_new: %{name: name, weekly_volume: wk, weekend_volume: wknd},
      choracle1: %{chat_id: chat_id}
    } do
      digest = %RoomieParser{
        table_manager: RoomieManager,
        parsed_params: %RoomieParser.ParsedParams{
          chat_id: chat_id,
          name: name,
          weekend_volume: wknd,
          weekly_volume: wk
        },
        cmd: :create
      }

      assert {:ok,
              %Cmd{
                args: [^chat_id, ^name, ^wk, ^wknd],
                cmd: :insert,
                digest: ^digest,
                response: %Roomie{
                  chat_id: ^chat_id,
                  name: ^name,
                  weekend_volume: ^wknd,
                  weekly_volume: ^wk
                }
              }} = Choracle.run_cmd(%Cmd{digest: digest})

      assert {:ok, _} = RoomieManager.get_one(chat_id, name)
    end

    test "create roomie with invalid volumes sum", %{
      mr_new: %{name: name, weekly_volume: wk, weekend_volume: wknd},
      choracle1: %{chat_id: chat_id}
    } do
      wknd = wknd + 1

      digest = %RoomieParser{
        table_manager: RoomieManager,
        parsed_params: %RoomieParser.ParsedParams{
          chat_id: chat_id,
          name: name,
          weekend_volume: wknd,
          weekly_volume: wk
        },
        cmd: :create
      }

      assert {:error, :volumes_sum_must_equal_max_volume} = Choracle.run_cmd(%Cmd{digest: digest})
    end

    test "create roomie twice", %{
      mr_slacker: %{name: name, weekly_volume: wk, weekend_volume: wknd},
      choracle1: %{chat_id: chat_id}
    } do
      digest = %RoomieParser{
        table_manager: RoomieManager,
        parsed_params: %RoomieParser.ParsedParams{
          chat_id: chat_id,
          name: name,
          weekend_volume: wknd,
          weekly_volume: wk
        },
        cmd: :create
      }

      assert {:error, :name_must_be_unique} = Choracle.run_cmd(%Cmd{digest: digest})
    end

    test "create roomie with unknwon chat id", %{
      mr_new: %{name: name, weekly_volume: wk, weekend_volume: wknd}
    } do
      digest = %RoomieParser{
        table_manager: RoomieManager,
        parsed_params: %RoomieParser.ParsedParams{
          chat_id: 999,
          name: name,
          weekend_volume: wknd,
          weekly_volume: wk
        },
        cmd: :create
      }

      assert {:error, :not_found} = Choracle.run_cmd(%Cmd{digest: digest})
    end

    test "get one roomie", %{
      mr_clean: %{name: name} = mr_clean,
      choracle1: %{chat_id: chat_id}
    } do
      digest = %RoomieParser{
        table_manager: RoomieManager,
        parsed_params: %RoomieParser.ParsedParams{chat_id: chat_id, name: name},
        cmd: :read,
        type: :one
      }

      assert {:ok,
              %Choracle.Cmd{
                args: [^chat_id, ^name],
                cmd: :get_one,
                digest: ^digest,
                response: ^mr_clean
              }} = Choracle.run_cmd(%Cmd{digest: digest})
    end

    test "get all roomies", %{
      mr_clean: mr_clean,
      mr_slacker: mr_slacker,
      choracle1: %{chat_id: chat_id}
    } do
      digest = %RoomieParser{
        table_manager: RoomieManager,
        parsed_params: %RoomieParser.ParsedParams{chat_id: chat_id},
        cmd: :read,
        type: :all
      }

      assert {:ok,
              %Choracle.Cmd{
                args: [^chat_id],
                cmd: :get_all,
                digest: ^digest,
                response: [^mr_clean, ^mr_slacker]
              }} = Choracle.run_cmd(%Cmd{digest: digest})
    end

    test "update roomie", %{
      mr_slacker: %{name: name, weekend_volume: wk, weekly_volume: wknd},
      choracle1: %{chat_id: chat_id}
    } do
      wk = wk - 1
      wknd = wknd + 1

      digest = %RoomieParser{
        table_manager: RoomieManager,
        parsed_params: %RoomieParser.ParsedParams{
          chat_id: chat_id,
          name: name,
          weekend_volume: wknd,
          weekly_volume: wk
        },
        cmd: :update
      }

      assert {:ok,
              %Choracle.Cmd{
                args: [^chat_id, ^name, %{weekend_volume: ^wknd, weekly_volume: ^wk}],
                cmd: :update,
                digest: ^digest,
                response: %Choracle.Repo.Roomie{
                  chat_id: ^chat_id,
                  name: ^name,
                  weekend_volume: ^wknd,
                  weekly_volume: ^wk
                }
              }} = Choracle.run_cmd(%Cmd{digest: digest})
    end

    test "update roomie with invalid volumes", %{
      mr_slacker: %{name: name, weekend_volume: wk, weekly_volume: wknd},
      choracle1: %{chat_id: chat_id}
    } do
      wk = wk - 1

      digest = %RoomieParser{
        table_manager: RoomieManager,
        parsed_params: %RoomieParser.ParsedParams{
          chat_id: chat_id,
          name: name,
          weekend_volume: wknd,
          weekly_volume: wk
        },
        cmd: :update
      }

      assert {:error, :volumes_sum_must_equal_max_volume} = Choracle.run_cmd(%Cmd{digest: digest})
    end

    test "update roomie with not found chat id", %{
      mr_slacker: %{name: name, weekend_volume: wk, weekly_volume: wknd}
    } do
      digest = %RoomieParser{
        table_manager: RoomieManager,
        parsed_params: %RoomieParser.ParsedParams{
          chat_id: 999,
          name: name,
          weekend_volume: wknd,
          weekly_volume: wk
        },
        cmd: :update
      }

      assert {:error, :not_found} = Choracle.run_cmd(%Cmd{digest: digest})
    end

    test "delete roomie", %{mr_slacker: %{name: name}, choracle1: %{chat_id: chat_id}} do
      digest = %RoomieParser{
        table_manager: RoomieManager,
        parsed_params: %RoomieParser.ParsedParams{
          chat_id: chat_id,
          name: name
        },
        cmd: :delete
      }

      assert {:ok, _} = RoomieManager.get_one(chat_id, name)
      Choracle.run_cmd(%Cmd{digest: digest})
      assert {:error, :not_found} = RoomieManager.get_one(chat_id, name)
    end
  end
end
