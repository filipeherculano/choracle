defmodule Choracle.Repo.Migrations.ChangeRoomieAssoc do
  use Ecto.Migration

  def change do
    alter table(:roomie) do
      add :chat_id, references(:choracle, type: :integer, column: :chat_id)
    end
  end
end
