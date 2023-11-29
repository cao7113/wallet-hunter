defmodule AddressFinder do
  def find_key(nil, _match_fn, _next_key_fn, _cursor, _init_key_int) do
    :not_found_at_end
  end

  def find_key(k, match_fn, next_key_fn, cursor, init_key_int) do
    addr =
      k
      |> KeyHelper.pubkey_from()
      |> KeyHelper.address_from()

    if match_fn.(addr) do
      {addr, k, cursor}
    else
      nk = next_key_fn.(k, cursor, init_key_int)
      find_key(nk, match_fn, next_key_fn, cursor + 1, init_key_int)
    end
  end

  def step_find(matcher, max_times \\ 50_000, init_k \\ KeyHelper.gen_private_key_bytes()) do
    init_k_int = init_k |> KeyHelper.as_integer()

    find_key(
      init_k,
      matcher,
      fn _last_key, c, init_int ->
        if c < max_times do
          # step forward
          init_int + c * 2
        end
      end,
      0,
      init_k_int
    )
  end

  def prefix_step_find(
        prefix \\ "0x123",
        max_times \\ 100_000,
        init_k \\ KeyHelper.gen_private_key_bytes()
      ) do
    step_find(
      fn addr ->
        String.starts_with?(addr, prefix)
      end,
      max_times,
      init_k
    )
  end

  # STOP when first hit to avoid wait to last over TODO!!!
  # use Rust version
  def prefix_step_find_in_para(
        prefix \\ "0x123",
        max_times \\ 100_000,
        concurrency \\ System.schedulers_online() |> div(2)
      ) do
    1..concurrency
    |> Task.async_stream(
      fn _ ->
        prefix_step_find(prefix, max_times)
      end,
      max_concurrency: concurrency,
      ordered: false,
      timeout: :infinity
    )
    |> Stream.reject(fn
      {:ok, :not_found_at_end} -> true
      _ -> false
    end)
    |> Stream.map(fn {_, hit} ->
      hit
    end)
    |> Enum.take(concurrency)
  end
end
