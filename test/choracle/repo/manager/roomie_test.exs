defmodule Choracle.Repo.Manager.RoomieTest do
  use ExUnit.Case, async: true

  alias Choracle.Factory
  alias Choracle.Repo
  alias Choracle.Repo.Manager.Roomie, as: RoomieManager
  alias Choracle.Repo.Roomie

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    {:ok, Factory.build!(:setup)}
  end

  describe "insert/4" do
    test "smoke", %{
      mr_new: %{name: name, weekly_volume: wk, weekend_volume: wknd},
      choracle1: %{chat_id: chat_id}
    } do
      assert {:ok,
              %Roomie{chat_id: ^chat_id, name: "Mr. New", weekly_volume: 2, weekend_volume: 3}} =
               RoomieManager.insert(chat_id, name, wk, wknd)
    end

    test "with unknown chat_id", %{
      mr_new: %{name: name, weekly_volume: wk, weekend_volume: wknd}
    } do
      assert {:error, :not_found} = RoomieManager.insert(999, name, wk, wknd)
    end

    test "already present roomie should fail to insert", %{
      mr_slacker: mr_slacker,
      choracle1: %{chat_id: chat_id}
    } do
      %Roomie{name: name, weekly_volume: wk, weekend_volume: wknd} = mr_slacker
      assert {:error, :name_must_be_unique} = RoomieManager.insert(chat_id, name, wk, wknd)
    end

    test "already present roomie but on another chat should succeed to insert", %{
      mr_clean: mr_clean,
      choracle2: %{chat_id: chat_id}
    } do
      %Roomie{name: name, weekly_volume: wk, weekend_volume: wknd} = mr_clean

      assert {:ok,
              %Roomie{chat_id: ^chat_id, name: ^name, weekly_volume: ^wk, weekend_volume: ^wknd}} =
               RoomieManager.insert(chat_id, name, wk, wknd)
    end

    test "with out of range value on week volume should fail to insert", %{
      mr_clean: mr_clean,
      choracle1: %{chat_id: chat_id}
    } do
      %Roomie{name: name, weekly_volume: wk, weekend_volume: wknd} = %Roomie{
        mr_clean
        | weekly_volume: -1
      }

      assert {:error, :out_of_range} = RoomieManager.insert(chat_id, name, wk, wknd)
    end

    test "with out of range above value on week volume should fail to insert", %{
      mr_clean: mr_clean,
      choracle1: %{chat_id: chat_id}
    } do
      %Roomie{name: name, weekly_volume: wk, weekend_volume: wknd} = %Roomie{
        mr_clean
        | weekly_volume: 101
      }

      assert {:error, :out_of_range} = RoomieManager.insert(chat_id, name, wk, wknd)
    end

    test "with out of range value on weekend volume should fail to insert", %{
      mr_clean: mr_clean,
      choracle1: %{chat_id: chat_id}
    } do
      %Roomie{name: name, weekly_volume: wk, weekend_volume: wknd} = %Roomie{
        mr_clean
        | weekend_volume: -1
      }

      assert {:error, :out_of_range} = RoomieManager.insert(chat_id, name, wk, wknd)
    end

    test "with out of range above value on weekend volume should fail to insert", %{
      mr_clean: mr_clean,
      choracle1: %{chat_id: chat_id}
    } do
      %Roomie{name: name, weekly_volume: wk, weekend_volume: wknd} = %Roomie{
        mr_clean
        | weekend_volume: 101
      }

      assert {:error, :out_of_range} = RoomieManager.insert(chat_id, name, wk, wknd)
    end

    test "name must be A-Z and a-z characters", %{
      mr_clean: %{weekly_volume: wk, weekend_volume: wknd},
      choracle1: %{chat_id: chat_id}
    } do
      name_wrong = "."

      assert {:error, :name_format} = RoomieManager.insert(chat_id, name_wrong, wk, wknd)
    end

    test "name must not exceed 100 characters", %{
      mr_clean: %{weekly_volume: wk, weekend_volume: wknd},
      choracle1: %{chat_id: chat_id}
    } do
      name_with_101 =
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"

      assert {:error, :name_length} = RoomieManager.insert(chat_id, name_with_101, wk, wknd)
    end
  end

  describe "get_one/2" do
    test "smoke", %{
      choracle1: %{chat_id: chat_id},
      mr_slacker: %{name: name, weekend_volume: wk, weekly_volume: wknd}
    } do
      assert {:ok,
              %Roomie{chat_id: ^chat_id, name: ^name, weekend_volume: ^wk, weekly_volume: ^wknd}} =
               RoomieManager.get_one(chat_id, name)
    end

    test "with unknown chat id", %{mr_slacker: %{name: name}} do
      assert {:error, :not_found} = RoomieManager.get_one(999, name)
    end

    test "with name not present on that chat_id", %{
      choracle1: %{chat_id: chat_id},
      mr_new: %{name: name}
    } do
      assert {:error, :not_found} = RoomieManager.get_one(chat_id, name)
    end
  end

  describe "get_all/1" do
    test "smoke", %{choracle1: %{chat_id: chat_id}, mr_slacker: mr_slacker, mr_clean: mr_clean} do
      assert {:ok, [^mr_clean, ^mr_slacker]} = RoomieManager.get_all(chat_id)
    end

    test "with unknown chat id" do
      assert {:error, :not_found} = RoomieManager.get_all(999)
    end
  end

  describe "delete/1" do
    test "smoke", %{
      mr_clean: mr_clean,
      mr_slacker: %{name: name},
      choracle1: %{chat_id: chat_id}
    } do
      assert 6 = Roomie |> Repo.all() |> length()
      assert {:ok, %Roomie{name: ^name}} = RoomieManager.delete(chat_id, name)
      assert 5 = Roomie |> Repo.all() |> length()
      assert [^mr_clean] = Repo.all(Roomie) |> Enum.reject(&(&1.chat_id != chat_id))
    end

    test "with unknown Roomie", %{choracle1: %{chat_id: chat_id}} do
      assert {:error, :not_found} = RoomieManager.delete(chat_id, "Unknown")
    end

    test "with unknown chat id", %{mr_slacker: %{name: name}} do
      assert {:error, :not_found} = RoomieManager.delete(999, name)
    end
  end

  describe "update/1" do
    test "smoke", %{
      mr_slacker: %{name: name, weekly_volume: wk, weekend_volume: wknd},
      choracle1: %{chat_id: chat_id}
    } do
      wk = wk + 2
      wknd = wknd - 2
      new_slacker = %{weekly_volume: wk, weekend_volume: wknd}

      assert {:ok,
              %Roomie{chat_id: ^chat_id, name: ^name, weekly_volume: ^wk, weekend_volume: ^wknd}} =
               RoomieManager.update(chat_id, name, new_slacker)
    end

    test "with unknown Roomie", %{
      mr_slacker: %{weekly_volume: wk, weekend_volume: wknd},
      choracle1: %{chat_id: chat_id}
    } do
      wk = wk + 2
      wknd = wknd - 2
      new_slacker = %{weekly_volume: wk, weekend_volume: wknd}

      assert {:error, :not_found} = RoomieManager.update(chat_id, "Unknown", new_slacker)
    end

    test "with unknown chat id", %{
      mr_slacker: %{name: name, weekly_volume: wk, weekend_volume: wknd}
    } do
      wk = wk + 2
      wknd = wknd - 2
      new_slacker = %{weekly_volume: wk, weekend_volume: wknd}

      assert {:error, :not_found} = RoomieManager.update(999, name, new_slacker)
    end
  end
end
