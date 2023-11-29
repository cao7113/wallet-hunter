defmodule PunkHelper do
  @moduledoc """
  Cryptopunk helper for devived (extended) keys.

  NOTE:
  * cryptopunk use Mnemoniac package
  """
  alias Cryptopunk, as: Punk

  def rand_mnemonic_words(l \\ 12), do: Punk.create_mnemonic(l)
  def mnemonic_words, do: Mnemoniac.words()

  def derive(mnemonic \\ rand_mnemonic_words(12), path_str \\ build_path_string(), opts \\ [])
      when is_binary(mnemonic) and is_binary(path_str) do
    path = parse_path!(path_str)

    mnemonic
    |> Punk.create_seed(opts[:passphrase] || "")
    |> Punk.master_key_from_seed()
    |> Punk.derive_key(path)
  end

  def build_master_key_from(mnemonic \\ Punk.create_mnemonic(24), opts \\ []) do
    mnemonic
    |> Punk.create_seed(opts[:passphrase] || "")
    |> Punk.master_key_from_seed()
  end

  def pub_key_from(%Punk.Key{type: :private} = key), do: Punk.Key.public_from_private(key)
  def pub_key_compress(%Punk.Key{type: :public} = key), do: Punk.Utils.compress_public_key(key)

  ## Eth Address

  def eth_address!(%Punk.Key{} = key), do: Punk.Crypto.Ethereum.address(key)

  def eth_checksum_address!(addr) when is_binary(addr) do
    {:ok, ca} = Punk.Crypto.Ethereum.ChecksumEncoding.encode(addr)
    ca
  end

  ## BIP44 CKD Path

  def parse_path(path_str) when is_binary(path_str), do: Punk.parse_path(path_str)

  def parse_path!(path_str) when is_binary(path_str) do
    {:ok, p} = parse_path(path_str)
    p
  end

  def build_path_string(coin_symbol \\ :ETH, opts \\ []) do
    account_path(coin_symbol, opts) |> to_path_string()
  end

  @doc """
  Get account path from coin-type symbol

  Options:
    type: :public | :private
    purpose: 44
    account: default 0
    change: default 0
    address_index: default 0
  """
  def account_path(coin_symbol \\ :ETH, opts \\ [])

  def account_path(coin_symbol, opts) when is_atom(coin_symbol) do
    CoinTypes.by_symbol(coin_symbol).coin_type
    |> account_path(opts)
  end

  def account_path(coin_type, opts) when is_integer(coin_type) do
    opts
    |> Keyword.put(:coin_type, coin_type)
    |> Keyword.put_new(:purpose, 44)
    |> Keyword.put_new(:account, 0)
    |> Keyword.put_new(:change, 0)
    |> Keyword.put_new(:address_index, 0)
    |> Punk.Derivation.Path.new()
  end

  def to_path_string(
        %Punk.Derivation.Path{
          type: tp,
          purpose: pp,
          coin_type: coin_tp,
          account: account,
          change: change,
          address_index: idx
        } = _path
      ) do
    [
      path_type(tp),
      "#{pp}'",
      "#{coin_tp}'",
      "#{account}'",
      "#{change}",
      "#{idx}"
    ]
    |> Enum.join("/")
  end

  def to_path_string(p), do: p

  def path_type(:private), do: "m"
  def path_type(:public), do: "M"

  def coin_symbols,
    do:
      CoinTypes.coin_types()
      |> Enum.map(& &1.symbol)
      |> Enum.reject(fn s -> s == "" end)
      |> Enum.uniq()
      |> Enum.map(&String.to_atom/1)

  # https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki#master-key-generation
  # 4 byte: version bytes (mainnet: 0x0488B21E public, 0x0488ADE4 private; testnet: 0x043587CF public, 0x04358394 private)
  # Because of the choice of the version bytes, the Base58 representation will start with "xprv" or "xpub" on mainnet, "tprv" or "tpub" on testnet.
  @ekey_versions %{
    xpub: 0x0488B21E,
    xprv: 0x0488ADE4,
    tpub: 0x043587CF,
    tprv: 0x04358394
  }
  def ekey_versions, do: @ekey_versions

  @doc """
  Encode extended key
  """
  def encode_key(%{type: tp} = ekey, net_name \\ :mainnet) do
    version = @ekey_versions[key_version_name(tp, net_name)] |> :binary.encode_unsigned()
    Punk.serialize_key(ekey, version)
  end

  def decode_key(encoded_key) when is_binary(encoded_key), do: Punk.deserialize_key(encoded_key)

  def key_version_name(:public, :mainnet), do: :xpub
  def key_version_name(:private, :mainnet), do: :xprv
  # DEPRECATE as BIP-43
  def key_version_name(:public, :testnet), do: :tpub
  def key_version_name(:private, :testnet), do: :tprv
end
