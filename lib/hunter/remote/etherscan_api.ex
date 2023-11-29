# defmodule Hunter.EtherscanAPI do
#   require Logger

#   @behaviour Hunter.ExplorerAPI

#   # https://docs.etherscan.io/getting-started/endpoint-urls
#   @base_url "https://api.etherscan.io/api"

#   # https://docs.etherscan.io/api-endpoints/accounts#get-a-list-of-normal-transactions-by-address
#   @balance_params %{
#     module: "account",
#     action: "balance",
#     tag: "latest"
#   }
#   @tx_params %{
#     module: "account",
#     action: "txlist",
#     startblock: 0,
#     endblock: 18_587_703,
#     page: 1,
#     offset: 10,
#     sort: "asc"
#   }

#   # https://api-sepolia.etherscan.io/api
#   # https://api.etherscan.io/api?module=account&action=balance&address=0x541a775a8266725bad4d7979a7a65ce6a8a8ce32&tag=latest&apikey=
#   def test_balance(opts \\ []) do
#     ak = "xxx"

#     # https://docs.bscscan.com/getting-started/endpoint-urls
#     base_url = @base_url
#     # base_url = "https://api.bscscan.com/api"
#     # base_url = "https://api-testnet.bscscan.com/api"

#     # "#{base_url}?module=account&action=balance&address=0x541a775a8266725bad4d7979a7a65ce6a8a8ce32&tag=latest&apikey=#{ak}"
#     url =
#       url = "https://twitter.com"

#     opts =
#       opts
#       |> Keyword.put(:connect_options,
#         proxy: {:http, "localhost", 1080, []},
#         proxy_headers: []
#         # log: true
#       )

#     Req.new(url: url)
#     |> Req.Request.put_header(
#       "user-agent",
#       "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36"
#     )
#     |> Req.Request.append_request_steps(
#       noop: fn request -> request end,
#       inspect: &IO.inspect/1
#     )
#     |> Req.Request.append_response_steps(
#       noop: fn {request, response} -> {request, response} end,
#       inspect: &IO.inspect/1
#     )
#     |> Req.request(opts)
#   end

#   # def proxy_opts(proxy, opts \\ []) do
#   #   opts
#   #   |> Keyword.put(:proxy, proxy)
#   # end

#   @impl true
#   def fetch_info(address) do
#     with {:ok, balance, _} <- fetch_balance(address),
#          {:ok, txs, _} <- fetch_txs(address) do
#       if balance > 0 or !Enum.empty?(txs) do
#         {:ok, %{balance: %{balance: balance, txs: true}, tx_count: Enum.count(txs)}}
#       else
#         {:ok, %{balance: nil, tx_count: nil}}
#       end
#     end
#   end

#   def fetch_balance(address) do
#     Sage.new()
#     |> Sage.run(:build_request, &build_request/2)
#     |> Sage.run(:maybe_wait_rate_limit, &maybe_wait_rate_limit/2)
#     |> Sage.run(:send_request, &send_request/2)
#     |> Sage.run(:parse_body, &parse_body/2)
#     |> Sage.run(:parse_balance, &parse_balance/2)
#     |> Sage.execute(%{address: address, request: :balance})
#   end

#   def fetch_txs(address) do
#     Sage.new()
#     |> Sage.run(:build_request, &build_request/2)
#     |> Sage.run(:maybe_wait_rate_limit, &maybe_wait_rate_limit/2)
#     |> Sage.run(:send_request, &send_request/2)
#     |> Sage.run(:parse_body, &parse_body/2)
#     |> Sage.run(:parse_txs, &parse_txs/2)
#     |> Sage.execute(%{address: address, request: :txs})
#   end

#   defp build_request(_effects_so_far, %{address: address, request: :balance}) do
#     encoded_params =
#       %{address: address, apikey: api_key()}
#       |> Map.merge(@balance_params)
#       |> URI.encode_query()

#     url = @base_url <> "?" <> encoded_params
#     request = Req.new(url: url)

#     {:ok, request}
#   end

#   defp build_request(_effects_so_far, %{address: address, request: :txs}) do
#     encoded_params =
#       %{address: address, apikey: api_key()}
#       |> Map.merge(@tx_params)
#       |> URI.encode_query()

#     url = @base_url <> "?" <> encoded_params
#     request = Req.new(url: url)

#     {:ok, request}
#   end

#   defp maybe_wait_rate_limit(_effects_so_far, _params) do
#     maybe_wait()
#   end

#   defp send_request(%{build_request: request}, _params) do
#     case Req.request(request) do
#       {:ok, %Req.Response{status: 200, body: body}} ->
#         {:ok, body}

#       {:ok, %Req.Response{body: body, status: status}} ->
#         {:error, "Request failed #{inspect(status)}: #{inspect(body)}"}

#       other ->
#         other
#     end
#   end

#   defp parse_body(%{send_request: body}, _params) do
#     Jason.decode(body)
#   end

#   defp parse_balance(
#          %{parse_body: %{"message" => "OK", "result" => balance, "status" => "1"}},
#          _
#        ) do
#     {:ok, String.to_integer(balance)}
#   end

#   defp parse_balance(%{parse_body: parse_body}, _) do
#     Logger.error("Failed to parse balance #{inspect(parse_body)}")

#     {:error, :response_error}
#   end

#   defp parse_txs(
#          %{parse_body: %{"message" => "No transactions found", "result" => [], "status" => "0"}},
#          _
#        ) do
#     {:ok, []}
#   end

#   defp parse_txs(
#          %{
#            parse_body: %{
#              "message" => "OK",
#              "result" => txs,
#              "status" => "1"
#            }
#          },
#          _
#        ) do
#     {:ok, txs}
#   end

#   defp parse_txs(%{parse_body: parse_body}, _) do
#     Logger.error("Failed to parse txs #{inspect(parse_body)}")

#     {:error, :response_error}
#   end

#   def api_key do
#     :hunter
#     |> Application.fetch_env!(__MODULE__)
#     |> Keyword.fetch!(:api_key)
#   end

#   defp maybe_wait do
#     case ExRated.check_rate("etherscan", 1_000, 3) do
#       {:ok, _} = result ->
#         result

#       _other ->
#         Process.sleep(1_000)
#         maybe_wait()
#     end
#   end
# end
