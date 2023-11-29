defmodule Hunter.Factory do
  use ExMachina.Ecto, repo: Hunter.Repo
  alias Hunter.Schema

  @valid_words_count [12, 15, 18, 21, 24]

  def mnemonic_factory do
    n = @valid_words_count |> Enum.random()

    %Schema.Mnemonic{
      length: n,
      words: Mnemoniac.create_mnemonic!(n)
    }
  end

  # mnemonic path derived key
  def key_factory do
    mn = build(:mnemonic)
    path_str = PunkHelper.build_path_string(:ETH)
    key = PunkHelper.derive(mn.words, path_str)
    priv_key = key.key |> Base.encode16(case: :lower)
    addr = PunkHelper.eth_address!(key)

    %Schema.Key{
      address: addr,
      private_key: priv_key,
      mnemonic: mn,
      path: path_str,
      note: "testing with mnemonic and path"
    }
  end

  def plain_key_factory do
    %{
      address: addr,
      private_key: priv_key
    } = KeyHelper.gen_account()

    %Schema.Key{
      address: addr,
      private_key: priv_key,
      mnemonic_id: nil,
      path: nil,
      note: "plain key testing"
    }
  end

  def address_factory do
    %Hunter.Schema.Address{
      address: KeyHelper.rand_address(),
      key_id: nil,
      txn_count: nil,
      balance: nil,
      fetch_at: nil,
      data: nil
    }
  end

  def address_with_key_factory do
    struct!(
      address_factory(),
      %{
        key: build(:key)
      }
    )
  end
end
