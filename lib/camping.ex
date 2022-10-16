defmodule Nhf1 do
  @moduledoc """
  Camping
  
  @author "Egyetemi Hallgató <egy.hallg@dp.vik.bme.hu>"
  @date   "2022-10-15"
  """

  # Number of rows (1 - n)
  @type row :: integer
  # Number of columns (1 - m)
  @type col :: integer
  # Coordinates of a field
  @type field :: {row, col}

  # Number of tents per row
  @type tents_count_rows :: [integer]
  # Number of tents per column
  @type tents_count_cols :: [integer]

  # Coordinates of the fields which have a tree on them
  @type trees :: [field]
  # Tuple describing the puzzle
  @type puzzle_desc :: {tents_count_rows, tents_count_cols, trees}

  # Direction of tent positions: north, east, south, west
  @type dir :: :n | :e | :s | :w
  # List of tent position directions relative to the trees
  @type tent_dirs :: [dir]

  @spec satrak(pd :: puzzle_desc) :: tss :: [tent_dirs]
  # tss is the list of all solutions of the puzzle described by pd in an arbitrary order
  def satrak({_tents_count_rows, _tents_count_cols, []}), do: []

  def satrak({tents_count_rows, tents_count_cols, trees}) do
    row_count = length(tents_count_rows)
    col_count = length(tents_count_cols)

    initial_map = init_tree_tent_map(trees)
    map = fill_map_with_possible_tent_fields(initial_map, row_count, col_count)

    find_solutions(map, tents_count_rows, tents_count_cols)
    |> Enum.map(fn items -> Enum.map(items, fn {dir, _tent} -> dir end) end)
  end

  defp init_tree_tent_map(trees) do
    for tree <- trees, into: %{}, do: {tree, %{}}
  end

  defp fill_map_with_possible_tent_fields(map, row_count, col_count) do
    for {tree, _value} <- map,
        into: %{},
        do: {tree, get_tree_neighbors(tree, row_count, col_count, map)}
  end

  defp get_tree_neighbors(tree, row_count, col_count, map) do
    for direction <- [:n, :e, :s, :w],
        (result = get_tree_neighbor(tree, direction, row_count, col_count, map)) !== nil,
        do: {direction, result}
  end

  defp get_tree_neighbor({i, j}, :n, _row_count, _col_count, map) do
    neighbor = {i - 1, j}
    if Map.has_key?(map, neighbor) || i === 1, do: nil, else: neighbor
  end

  defp get_tree_neighbor({i, j}, :e, _row_count, col_count, map) do
    neighbor = {i, j + 1}
    if Map.has_key?(map, neighbor) || j === col_count, do: nil, else: neighbor
  end

  defp get_tree_neighbor({i, j}, :s, row_count, _col_count, map) do
    neighbor = {i + 1, j}
    if Map.has_key?(map, neighbor) || i === row_count, do: nil, else: neighbor
  end

  defp get_tree_neighbor({i, j}, :w, _row_count, _col_count, map) do
    neighbor = {i, j - 1}
    if Map.has_key?(map, neighbor) || j === 1, do: nil, else: neighbor
  end

  defp find_solutions(tree_tent_map, tents_count_rows, tents_count_cols),
    do: find_solutions(tree_tent_map, tents_count_rows, tents_count_cols, [])

  defp find_solutions(tree_tent_map, tents_count_rows, tents_count_cols, tents)
       when map_size(tree_tent_map) === 0 do
    if solution_satisfies_row_constraint?(tents, tents_count_rows) &&
         solution_satisfies_col_constraint?(tents, tents_count_cols),
       do: [tents],
       else: nil
  end

  defp find_solutions(tree_tent_map, tents_count_rows, tents_count_cols, tents_so_far) do
    picked_tree = Map.keys(tree_tent_map) |> hd()
    tents = Map.get(tree_tent_map, picked_tree)

    result =
      for {dir, tent} <- tents,
          !violates_row_constraint?(tent, tents_so_far, tents_count_rows),
          !violates_col_constraint?(tent, tents_so_far, tents_count_cols),
          !touches_other_tent?(tent, tents_so_far),
          result =
            find_solutions(
              Map.delete(tree_tent_map, picked_tree),
              tents_count_rows,
              tents_count_cols,
              tents_so_far ++ [{dir, tent}]
            ),
          result !== nil,
          do: result

    result |> Enum.flat_map(fn item -> item end)
  end

  defp violates_row_constraint?({i, _j}, tents_so_far, tents_count_rows) do
    expected_row_count = Enum.at(tents_count_rows, i - 1)
    row_tents_so_far = tents_so_far |> Enum.filter(fn {_dir, {a, _b}} -> a === i end)

    expected_row_count >= 0 && length(row_tents_so_far) + 1 > expected_row_count
  end

  defp violates_col_constraint?({_i, j}, tents_so_far, tents_count_cols) do
    expected_col_count = Enum.at(tents_count_cols, j - 1)
    col_tents_so_far = tents_so_far |> Enum.filter(fn {_dir, {_a, b}} -> b === j end)

    expected_col_count >= 0 && length(col_tents_so_far) + 1 > expected_col_count
  end

  defp touches_other_tent?({i, j}, tents_so_far) do
    Enum.any?(tents_so_far, fn {_dir, {a, b}} -> abs(a - i) <= 1 && abs(b - j) <= 1 end)
  end

  defp solution_satisfies_row_constraint?(solution, tents_count_rows) do
    matches =
      for i <- 0..(length(tents_count_rows) - 1) do
        tents_count_row = Enum.at(tents_count_rows, i)

        row_tents = solution |> Enum.filter(fn {_dir, {a, _j}} -> a === i + 1 end)
        tents_count_row < 0 || length(row_tents) === tents_count_row
      end

    Enum.all?(matches, fn item -> item === true end)
  end

  defp solution_satisfies_col_constraint?(solution, tents_count_cols) do
    matches =
      for i <- 0..(length(tents_count_cols) - 1) do
        tents_count_col = Enum.at(tents_count_cols, i)

        col_tents = solution |> Enum.filter(fn {_dir, {_a, b}} -> b === i + 1 end)
        tents_count_col < 0 || length(col_tents) === tents_count_col
      end

    Enum.each(matches, fn item -> item === true end)
  end
end
