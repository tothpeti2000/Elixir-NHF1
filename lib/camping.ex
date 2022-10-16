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
  def satrak(_tents_count_rows, _tents_count_cols, []), do: []

  def satrak({tents_count_rows, tents_count_cols, trees}) do
    row_count = length(tents_count_rows)
    col_count = length(tents_count_cols)

    map = init_tree_tent_map(trees)
    map = get_possible_tent_fields(map, row_count, col_count)

    find_solutions(map, tents_count_rows, tents_count_cols)

    # Get all possible directions

    # Check if there's a tent which has only one direction left => fix solution
    #   Check if the fix tent is in a row or column with only one tent required => remove all other tents from the row or column
    #   Remove the fix tent from other trees which it could've been attached to + remove all surrounding trees

    # If there are trees with multiple possibilities left, pick the one with the lowest row or column constraint
    #   If we can't place enough tents in this row or column by picking the tent, abort the branch right away
    #   If we exceed the number of rows or columns by picking this tree, abort the branch right away
    #   Optional: If we match the row or column constraint, remove all other tents from the corresponding trees

    # If all trees have one possible tent attached to them, we found a solution

    # possible_tent_fields = get_possible_tent_fields(pd)
  end

  defp init_tree_tent_map(trees) do
    for tree <- trees, into: %{}, do: {tree, %{}}
  end

  defp get_possible_tent_fields(map, row_count, col_count) do
    for {tree, _value} <- map,
        into: %{},
        do: {tree, get_tree_neighbors(tree, row_count, col_count, map)}
  end

  defp get_tree_neighbors(tree, row_count, col_count, map) do
    for direction <- [:n, :e, :s, :w],
        (result = get_tree_neighbor(tree, direction, row_count, col_count, map)) !== nil,
        into: %{},
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

  defp find_solutions(tree_tent_map, _tents_count_rows, _tents_count_cols, tents)
       when map_size(tree_tent_map) === 0,
       do: tents

  defp find_solutions(tree_tent_map, tents_count_rows, tents_count_cols, tents_so_far) do
    # IO.inspect(tree_tent_map)
    first_tree = Map.keys(tree_tent_map) |> hd()
    tent_map = Map.get(tree_tent_map, first_tree)

    for {dir, tent} <- tent_map,
        !violates_row_constraint?(tent, tents_so_far, tents_count_rows),
        !violates_col_constraint?(tent, tents_so_far, tents_count_cols),
        !touches_other_tent?(tent, tents_so_far),
        result =
          find_solutions(
            Map.delete(tree_tent_map, first_tree),
            tents_count_rows,
            tents_count_cols,
            tents_so_far ++ [{dir, tent}]
          ),
        length(result) !== 0,
        do: result
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
end
