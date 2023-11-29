defmodule Hunter.Repo do
  use Ecto.Repo,
    otp_app: :hunter,
    adapter: Ecto.Adapters.Postgres

  import Ecto.Query

  def stats(schema \\ Hunter.Schema.Key) when is_atom(schema) do
    schema
    |> select([i], %{
      total_count: count(i.id),
      min_id: min(i.id),
      max_id: max(i.id),
      min_inserted_at: min(i.inserted_at),
      max_updated_at: max(i.updated_at)
    })
    |> one()
  end

  @doc """
  Loop up items as id asc

  Note: query should without order_by and limit
  """
  def loop_up(q, batch_fn, opts \\ []) do
    q = loop_clean_query(q)
    from_id = q |> aggregate(:min, :id)
    size = opts[:batch_size] || 100
    do_loop_up(q, from_id, size, batch_fn, [])
  end

  def do_loop_up(q, from_idx, size, batch_fn, acc) do
    q
    |> where([i], i.id >= ^from_idx)
    |> order_by([i], asc: :id)
    |> limit(^size)
    |> all()
    |> case do
      [] ->
        {:ok, acc}

      items ->
        new_acc = batch_fn.(items, acc)

        if length(items) < size do
          {:ok, acc}
        else
          do_loop_up(q, from_idx + size, size, batch_fn, new_acc)
        end
    end
  end

  def loop_down(q, batch_fn, opts \\ []) do
    q = loop_clean_query(q)
    from_id = q |> aggregate(:max, :id)
    size = opts[:batch_size] || 100
    do_loop_down(q, from_id, size, batch_fn, [])
  end

  def do_loop_down(q, from_idx, size, batch_fn, acc) do
    q
    |> where([i], i.id <= ^from_idx)
    |> order_by([i], desc: :id)
    |> limit(^size)
    |> all()
    |> case do
      [] ->
        {:ok, acc}

      items ->
        new_acc = batch_fn.(items, acc)

        if length(items) < size do
          {:ok, acc}
        else
          do_loop_down(q, from_idx - size, size, batch_fn, new_acc)
        end
    end
  end

  def loop_clean_query(q) do
    q
    |> exclude(:order_by)
    |> exclude(:offset)
    |> exclude(:limit)
  end
end
