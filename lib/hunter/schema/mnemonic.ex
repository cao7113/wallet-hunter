defmodule Hunter.Schema.Mnemonic do
  use Ecto.Schema
  use Endon
  import Ecto.Changeset

  schema "mnemonics" do
    field :length, :integer
    field :words, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(mnemonic, attrs) do
    mnemonic
    |> cast(attrs, [:length, :words])
    |> validate_required([:length, :words])
    |> unique_constraint(:words)
  end
end
