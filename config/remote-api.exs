import Config

config :hunter, Hunter.Remote.BscscanAPI,
  # https://docs.bscscan.com/getting-started/endpoint-urls
  mainnet: [
    base_url: "https://api.bscscan.com/api",
    api_key: {:system, "REMOTE_BSCSCAN_PROD_API_KEY", "unset-secret"},
    token_usdt: "0x55d398326f99059fF775485246999027B3197955"
  ],
  testnet: [
    base_url: "https://api-testnet.bscscan.com/api",
    # testnet 不需要api-key？
    api_key: {:system, "REMOTE_BSCSCAN_TEST_API_KEY", "test-api-xxx"}
  ]
