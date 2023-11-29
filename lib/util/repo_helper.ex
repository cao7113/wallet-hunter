defmodule RepoHelper do
  def insert_all_quietly(items, schema, opts \\ []) do
    insert_all(items, schema, opts |> Keyword.put(:on_conflict, :nothing))
  end

  def insert_all(items, schema_mod, opts \\ [])

  def insert_all(items, schema_mod, opts) when is_list(items) and is_atom(schema_mod) do
    {batch_size, opts} = Keyword.pop(opts, :batch_size, 500)
    {repo, opts} = Keyword.pop(opts, :repo, AppHelper.default_repo())

    items
    |> Enum.chunk_every(batch_size)
    |> Enum.reduce({0, nil}, fn chunked_itmes, {total, acc_items} ->
      tm = DateTime.utc_now() |> DateTime.truncate(:second)

      insert_items =
        chunked_itmes
        |> Enum.map(fn it ->
          it
          |> Map.merge(%{
            inserted_at: {:placeholder, :inserted_at},
            updated_at: {:placeholder, :updated_at}
          })
        end)

      insert_opts =
        [
          placeholders: %{
            inserted_at: tm,
            updated_at: tm
          }
        ]
        |> Keyword.merge(opts)

      {insert_size, inserted_items} = repo.insert_all(schema_mod, insert_items, insert_opts)
      {total + insert_size, merge_items(acc_items, inserted_items)}
    end)
  end

  def insert_all(item, schema_mod, opts) when is_atom(schema_mod),
    do: insert_all([item], schema_mod, opts)

  def merge_items(nil, nil), do: nil
  def merge_items(nil, items) when is_list(items), do: items
  def merge_items(acc, nil) when is_list(acc), do: acc
  def merge_items(acc, this) when is_list(acc) and is_list(this), do: acc ++ this
end
