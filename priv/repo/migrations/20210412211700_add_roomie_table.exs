defmodule Choracle.Repo.Migrations.AddRoomieTable do
  use Ecto.Migration

  def up do
    create table("roomie", primary_key: false) do
      add :name, :string, size: 100, primary_key: true
      add :weekly_volume, :integer, null: false
      add :weekend_volume, :integer, null: false
      add :max_volume, :integer, null: false

      timestamps()
    end

    create constraint("roomie", :volumes_sum_must_equal_max_volume,
             check: "(weekly_volume + weekend_volume) = max_volume"
           )

    create constraint("roomie", :weekly_volume_ranges,
             check: "weekly_volume > 0 and weekly_volume < 101"
           )

    create constraint("roomie", :weekend_volume_ranges,
             check: "weekend_volume > 0 and weekend_volume < 101"
           )

    create constraint("roomie", :max_volume_ranges, check: "max_volume > 0 and max_volume < 101")
  end

  def down do
    drop table("roomie")
  end
end
