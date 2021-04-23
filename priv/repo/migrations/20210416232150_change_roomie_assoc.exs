defmodule Choracle.Repo.Migrations.ChangeRoomieAssoc do
  use Ecto.Migration

  def change do
    alter table(:roomie) do
      add :chat_id,
          references(:choracle, type: :integer, column: :chat_id, on_delete: :delete_all)
    end

    create unique_index(:roomie, [:chat_id, :name], name: :roomie_chat_id_name_index)
  end
end
