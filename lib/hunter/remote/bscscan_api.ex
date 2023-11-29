defmodule Hunter.Remote.BscscanAPI do
  require Logger

  @doc """
  Get account balance by address

  https://docs.etherscan.io/api-endpoints/accounts#get-ether-balance-for-a-single-address
  """
  def req_balance(addr, opts \\ []) do
    remote_conf = config_for(opts)

    params = %{
      module: "account",
      action: "balance",
      tag: opts[:tag] || "latest",
      address: addr,
      apikey: remote_conf[:api_key]
    }

    Req.new(url: remote_conf[:base_url], params: params)
    # |> Req.Request.append_request_steps(
    #   noop: fn request -> request end,
    #   inspect: &IO.inspect/1
    # )
    # |> Req.Request.append_response_steps(
    #   noop: fn {request, response} -> {request, response} end,
    #   inspect: &IO.inspect/1
    # )
    |> Req.request(opts)
    |> case do
      {:ok, %{status: 200, body: %{"message" => "OK", "result" => result, "status" => "1"}}} ->
        {:ok, result |> String.to_integer()}

      failed ->
        failed
    end
  end

  @doc """
  Get balances for a list of addresses
  TODO: HOW TO MOCK

  https://docs.etherscan.io/api-endpoints/accounts#get-ether-balance-for-multiple-addresses-in-a-single-call
  """
  def req_balances(addrs, opts \\ []) when is_list(addrs) do
    remote_conf = config_for(opts)

    params = %{
      module: "account",
      action: "balancemulti",
      tag: opts[:tag] || "latest",
      address: Enum.join(addrs, ","),
      apikey: remote_conf[:api_key]
    }

    Req.new(url: remote_conf[:base_url], params: params)
    |> Req.request(opts)
    |> case do
      {:ok, %{status: 200, body: %{"message" => "OK", "result" => result, "status" => "1"}}} ->
        # [
        #   %{
        #     "account" => "0x541a775a8266725bad4d7979a7a65ce6a8a8ce32",
        #     "balance" => "0"
        #   }
        # ]
        items =
          result
          |> Enum.map(fn %{"balance" => bal} = it ->
            it |> Map.put("balance", bal |> as_integer())
          end)

        {:ok, items}

      failed ->
        failed
    end
  end

  def req_token_balance(addr, token_addr \\ :token_usdt, opts \\ []) do
    #   https://api.bscscan.com/api
    #  ?module=account
    #  &action=tokenbalance
    #  &contractaddress=0xe9e7cea3dedca5984780bafc599bd69add087d56
    #  &address=0x89e73303049ee32919903c09e8de5629b84f59eb
    #  &tag=latest
    #  &apikey=YourApiKeyToken

    remote_conf = config_for(opts)
    token_addr = token_address(token_addr, remote_conf)

    params = %{
      module: "account",
      action: "tokenbalance",
      address: addr,
      contractaddress: token_addr,
      tag: opts[:tag] || "latest",
      apikey: remote_conf[:api_key]
    }

    Req.new(url: remote_conf[:base_url], params: params)
    |> Req.request(opts)
    |> case do
      {:ok, %{status: 200, body: %{"message" => "OK", "result" => result, "status" => "1"}}} ->
        # {
        #   "status":"1",
        #   "message":"OK",
        #   "result":"1420514928941209"
        # }
        {:ok, result |> as_integer()}

      failed ->
        failed
    end
  end

  def token_address(token_symbol, conf) when is_atom(token_symbol), do: conf[token_symbol]
  def token_address(token_addr, _) when is_binary(token_addr), do: token_addr

  @doc """
  Returns the list of transactions performed by an address, with optional pagination.
  """
  def req_txs(addr, opts \\ []) do
    remote_conf = config_for(opts)

    # start_block = opts[:start_block] || 0
    # end_block = opts[:end_block] || 99900

    params = %{
      module: "account",
      action: "txlist",
      address: addr,
      # startblock: start_block,
      # endblock: end_block,
      sort: opts[:sort] || "desc",
      page: opts[:page] || 1,
      offset: opts[:offset] || 10,
      apikey: remote_conf[:api_key]
    }

    Req.new(url: remote_conf[:base_url], params: params)
    |> Req.Request.append_request_steps(
      # noop: fn request -> request end,
      inspect: &IO.inspect/1
    )
    |> Req.request()
    |> case do
      {:ok,
       %{
         status: 200,
         body: %{
           "message" => "No transactions found",
           "result" => [],
           "status" => "0"
         }
       }} ->
        {:ok, []}

      {:ok,
       %{
         status: 200,
         body: %{
           "message" => "OK",
           "result" => result,
           "status" => "1"
         }
       }} ->
        {:ok, result |> Enum.map(&pretty_tx/1)}

      failed ->
        failed
    end
  end

  def pretty_tx(
        %{
          "blockHash" => blockHash,
          "blockNumber" => blockNumber,
          "confirmations" => confirmations,
          "contractAddress" => contractAddress,
          # "cumulativeGasUsed" => "16181298",
          "from" => from,
          # "functionName" => "transfer(address _to, uint256 _value)",
          "gas" => gas,
          "gasPrice" => gasPrice,
          # "gasUsed" => "29703",
          "hash" => hash,
          "input" => input,
          # "isError" => "0",
          # "methodId" => methodId,
          "nonce" => nonce,
          "timeStamp" => timeStamp,
          "to" => to,
          "transactionIndex" => transactionIndex,
          # "txreceipt_status" => "1",
          "value" => value
        } = _tx
      ) do
    ts = timeStamp |> as_integer()

    %{
      blockNumber: blockNumber |> as_integer(),
      timeStamp: ts,
      timeStampAt: ts |> DateTime.from_unix!(),
      hash: hash,
      nonce: nonce |> as_integer(),
      blockHash: blockHash,
      transactionIndex: transactionIndex |> as_integer(),
      from: from,
      to: to,
      value: value |> as_integer(),
      gas: gas |> as_integer(),
      gasPrice: gasPrice |> as_integer(),
      # isError: _,
      # txreceipt_status: _,
      input: input,
      contractAddress: contractAddress,
      # cumulativeGasUsed: _,
      # gasUsed: _,
      # methodId: methodId,
      confirmations: confirmations |> as_integer()
    }
  end

  def as_integer(""), do: 0
  def as_integer(str), do: String.to_integer(str)

  def config_for(opts \\ []) do
    Confex.fetch_env!(:hunter, __MODULE__)[remote_name(opts[:remote])]
  end

  def remote_name(nil), do: :mainnet
  def remote_name(n) when is_atom(n), do: n
end
