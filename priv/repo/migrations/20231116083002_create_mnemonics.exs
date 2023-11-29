defmodule Hunter.Repo.Migrations.CreateMnemonics do
  use Ecto.Migration

  def change do
    create table(:mnemonics) do
      add :length, :integer
      add :words, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:mnemonics, [:words])
  end
end
