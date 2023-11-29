defmodule Hunter.Repo.Migrations.CreateKeys do
  use Ecto.Migration

  def change do
    create table(:keys) do
      add :address, :binary, null: false
      add :private_key, :string, null: false
      add :mnemonic_id, :integer
      add :path, :string
      add :note, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:keys, :address)
    create unique_index(:keys, :private_key)
    create unique_index(:keys, [:mnemonic_id, :path])
  end
end
