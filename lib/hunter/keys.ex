defmodule Hunter.Keys do
  alias Types.EvmAddress
  alias Hunter.Repo
  alias Hunter.Schema
  alias Cryptopunk, as: Punk
  import Ecto.Query

  ## Key Finder

  def find_keys(addrs) when is_list(addrs) do
    Schema.Key.where(address: addrs)
  end

  def find_key(addr) do
    Schema.Key.find_by(address: addr)
  end

  ## Key Generator

  def gen_mnemonic_path_key(
        path_str \\ PunkHelper.build_path_string(:ETH),
        mnemonic_query \\ unkeyed_mnemonic_query()
      ) do
    stream = Repo.stream(mnemonic_query, max_rows: 500)

    Repo.transaction(fn ->
      stream
      |> Enum.map(fn m ->
        path_key_attrs(m, path_str)
      end)
      |> RepoHelper.insert_all_quietly(Schema.Key)
    end)
  end

  def unkeyed_mnemonic_query() do
    last_mid = Schema.Key.max(:mnemonic_id) || 0
    from(p in Schema.Mnemonic, where: p.id > ^last_mid)
  end

  def path_key_attrs(
        %{words: words, id: mid} = _mnemonic,
        path_str \\ PunkHelper.build_path_string(:ETH)
      )
      when is_binary(path_str) do
    dkey = PunkHelper.derive(words, path_str)
    addr = PunkHelper.eth_address!(dkey) |> EvmAddress.cast!()

    %{
      mnemonic_id: mid,
      path: path_str,
      address: addr,
      private_key: dkey.key |> Base.encode16(case: :lower)
    }
  end

  ## Mnemonic Generator

  def init_same_word_mnemonics!(lens \\ [12, 15, 18, 21, 24], opts \\ []) do
    lens
    |> Enum.map(fn l ->
      gen_same_word_mnemonics(l, opts)
    end)
  end

  def gen_same_word_mnemonics(times \\ 12, opts \\ []) do
    PunkHelper.mnemonic_words()
    |> Enum.map(fn word ->
      words = word |> List.duplicate(times) |> Enum.join(" ")

      %{
        words: words,
        length: times
      }
    end)
    |> RepoHelper.insert_all_quietly(Hunter.Schema.Mnemonic, opts)
  end

  def gen_rand_mnemonics(word_num \\ 12, opts \\ []) do
    num = opts[:num] || 1000

    Stream.repeatedly(fn ->
      Punk.create_mnemonic(word_num)
    end)
    |> Stream.take(num)
    |> Enum.map(fn words ->
      %{
        words: words,
        length: word_num
      }
    end)
    |> RepoHelper.insert_all_quietly(Hunter.Schema.Mnemonic, opts)
  end
end
