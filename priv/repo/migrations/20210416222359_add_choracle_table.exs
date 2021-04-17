defmodule Choracle.Repo.Migrations.AddChoracleTable do
  use Ecto.Migration

  def up do
    create table(:choracle, primary_key: false) do
      add :chat_id, :integer, primary_key: true
      add :max_volume, :integer, null: false

      timestamps()
    end

    create constraint(:choracle, :max_volume_range, check: "max_volume > 0 and max_volume < 201")
  end

  def down do
    drop(:choracle)
  end
end
