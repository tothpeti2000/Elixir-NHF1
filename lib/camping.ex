defmodule Nhf1 do
  @moduledoc """
  Camping
  
  @author "Tóth Péter tothpeti2000@edu.bme.hu"
  @date   "2022-10-16"
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

  # Tuple containing the tent field and the direction relative to its tree
  @type tent_placement :: {dir, field}
  # Map where the keys are the trees in the puzzle description and the values are the possible tents of the trees
  @type tree_tents_map :: %{field => [tent_placement]}

  # Map where the keys are the rows / columns in the puzzle and the values are the expected tent counts in the rows / columns
  @type tent_count_map :: %{integer => integer}

  @spec satrak(pd :: puzzle_desc) :: tss :: [tent_dirs]
  # tss is the list of all solutions of the puzzle described by pd in an arbitrary order
  def satrak({_tents_count_rows, _tents_count_cols, []}), do: []

  def satrak({tents_count_rows, tents_count_cols, trees}) do
    row_count = length(tents_count_rows)
    col_count = length(tents_count_cols)

    initial_map = init_tree_tents_map(trees)
    tree_tents_map = fill_map_with_possible_tent_placements(initial_map, row_count, col_count)

    row_tent_count_map = create_tent_count_map(tents_count_rows)
    col_tent_count_map = create_tent_count_map(tents_count_cols)

    # The solution list returned by find_solutions looks like this: [ [{:n, {1, 1}}, {:n, {4, 1}}],
    #                                                                 [{:n, {1, 1}, {:s, {5, 1}}}] ]
    # Since the solutions contain the tent fields as well, we have to use Enum.map to get the directions only
    find_solutions(tree_tents_map, row_tent_count_map, col_tent_count_map)
    |> Enum.map(fn solution -> Enum.map(solution, fn {dir, _tent_field} -> dir end) end)
  end

  @spec init_tree_tents_map(trees :: trees) :: initial_map :: tree_tents_map
  # Initializes a map where the keys are the tree fields in the puzzle description and the values are empty lists
  defp init_tree_tents_map(trees) do
    for tree <- trees, into: %{}, do: {tree, []}
  end

  @spec fill_map_with_possible_tent_placements(
          map :: tree_tents_map,
          row_count :: integer,
          col_count :: integer
        ) ::
          filled_map :: tree_tents_map
  # Creates a tent-tree map where the value of each key is a list of all possible tent fields of the corresponding tree
  defp fill_map_with_possible_tent_placements(map, row_count, col_count) do
    for tree <- Map.keys(map),
        into: %{},
        do: {tree, get_tents_for_tree(tree, row_count, col_count, map)}
  end

  @spec get_tents_for_tree(
          tree :: field,
          row_count :: integer,
          col_count :: integer,
          map :: tree_tents_map
        ) :: [tent_placement]
  # Returns all possible tents for a tree considering the row count and column count in the puzzle description
  defp get_tents_for_tree(tree, row_count, col_count, map) do
    for direction <- [:n, :e, :s, :w],
        (result = get_tree_neighbor(tree, direction, row_count, col_count, map)) !== nil,
        do: {direction, result}
  end

  @spec get_tree_neighbor(
          tree :: field,
          direction :: dir,
          row_count :: integer,
          col_count :: integer,
          map :: tree_tents_map
        ) :: result :: field | nil
  # Returns the neighbor field of the tree in the given direction
  # If the neighbor field is out of bounds, we return nil since it isn't a valid field
  # If the neighbor field is occupied by a tree already, we can't place a tent on it so we return nil to indicate this
  # Otherwise, we can place a tent on the neighbor field so we return it
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

  @spec create_tent_count_map(tent_counts :: [integer]) ::
          tent_count_map :: tent_count_map
  # Converts the tents_count_rows / tents_count_cols list of the puzzle description to a map
  # E.g. [1, 0, 2] ---> %{1 => 1, 2 => 0, 3 => 2}
  defp create_tent_count_map(tent_counts) do
    for i <- 0..(length(tent_counts) - 1),
        into: %{},
        do: {i + 1, Enum.at(tent_counts, i)}
  end

  @spec find_solutions(
          tree_tents_map :: tree_tents_map,
          row_tent_count_map :: tent_count_map,
          col_tent_count_map :: tent_count_map
        ) :: solutions :: [[tent_placement]]
  # Finds all solutions of the puzzle using backtracking
  # We collect the tent placements in an accumulator which is an empty list initially
  defp find_solutions(tree_tents_map, row_tent_count_map, col_tent_count_map),
    do: find_solutions(tree_tents_map, row_tent_count_map, col_tent_count_map, [])

  @spec find_solutions(
          tree_tents_map :: tree_tents_map,
          row_tent_count_map :: tent_count_map,
          col_tent_count_map :: tent_count_map,
          tent_placements_so_far :: [tent_placement]
        ) :: solutions :: [[tent_placement]]
  # When we reach a leaf of the state space tree created by backtracking, we check if the solution fully satisfies the row and column constraints
  # If it does, we return it, otherwise, we return nil to indicate that it's an invalid solution
  # This is important because otherwise even those solutions would be marked valid which don't reach the minimum row or column tent count
  defp find_solutions(tree_tents_map, row_tent_count_map, col_tent_count_map, tent_placements)
       when map_size(tree_tents_map) === 0 do
    if solution_satisfies_row_constraints?(tent_placements, row_tent_count_map) &&
         solution_satisfies_col_constraints?(tent_placements, col_tent_count_map),
       do: [tent_placements],
       else: nil
  end

  # Recursively collect each solution of the puzzle using backtracking
  # In each iteration, we take the first tree of the tree-tent map
  # For each possible tent field of the tree, we check if picking that tent is a valid choice
  # If it doesn't violate any puzzle constraint, we pick that tent and drop its corresponding tree from the map
  # Otherwise, we terminate the branch since it's not a valid placement
  defp find_solutions(
         tree_tents_map,
         row_tent_count_map,
         col_tent_count_map,
         tent_placements_so_far
       ) do
    picked_tree = Map.keys(tree_tents_map) |> hd()
    tents = Map.get(tree_tents_map, picked_tree)

    solutions =
      for {dir, tent} <- tents,
          !violates_row_constraint?(tent, tent_placements_so_far, row_tent_count_map),
          !violates_col_constraint?(tent, tent_placements_so_far, col_tent_count_map),
          !touches_other_tent?(tent, tent_placements_so_far),
          solution =
            find_solutions(
              Map.delete(tree_tents_map, picked_tree),
              row_tent_count_map,
              col_tent_count_map,
              tent_placements_so_far ++ [{dir, tent}]
            ),
          solution !== nil,
          do: solution

    # Without flat_map, the solutions list would contain multiple levels of nesting
    solutions |> Enum.flat_map(& &1)
  end

  @spec violates_row_constraint?(
          tent :: field,
          tent_placements_so_far :: [tent_placement],
          row_tent_count_map :: tent_count_map
        ) :: result :: boolean
  # Checks if choosing the given tent results in exceeding the tent count limit of its row
  # If the limit is a negative number, we don't have to worry about exceeding the limit
  defp violates_row_constraint?({row, _col}, tent_placements_so_far, row_tent_count_map) do
    expected_tent_count = Map.get(row_tent_count_map, row)
    row_tents_so_far = tent_placements_so_far |> Enum.filter(fn {_dir, {i, _j}} -> i === row end)

    expected_tent_count >= 0 && length(row_tents_so_far) + 1 > expected_tent_count
  end

  @spec violates_col_constraint?(
          tent :: field,
          tent_placements_so_far :: [tent_placement],
          col_tent_count_map :: tent_count_map
        ) :: result :: boolean
  # Checks if choosing the given tent results in exceeding the tent count limit of its column
  # If the limit is a negative number, we don't have to worry about exceeding the limit
  defp violates_col_constraint?({_row, col}, tent_placements_so_far, col_tent_count_map) do
    expected_tent_count = Map.get(col_tent_count_map, col)
    col_tents_so_far = tent_placements_so_far |> Enum.filter(fn {_dir, {_i, j}} -> j === col end)

    expected_tent_count >= 0 && length(col_tents_so_far) + 1 > expected_tent_count
  end

  @spec touches_other_tent?(
          tent :: field,
          tent_placements_so_far :: [tent_placement]
        ) :: result :: boolean
  # Checks if the given tent touches any of the previously picked tents
  # Two tents touch each other if they're placed in a 2x2 square
  defp touches_other_tent?({row, col}, tent_placements_so_far),
    do:
      Enum.any?(tent_placements_so_far, fn {_dir, {i, j}} ->
        abs(i - row) <= 1 && abs(j - col) <= 1
      end)

  @spec solution_satisfies_row_constraints?(
          solution :: [tent_placement],
          row_tent_count_map :: tent_count_map
        ) ::
          result :: boolean
  # Checks if the given solution fully satisfies all row constraints
  # We check the constraint for each row and put the results into a list
  # If each item in the list is true, the solution satisfies all row constraints
  defp solution_satisfies_row_constraints?(solution, row_tent_count_map) do
    rows_match_expected_count =
      for {row, expected_tent_count} <- row_tent_count_map do
        row_tents = solution |> Enum.filter(fn {_dir, {i, _j}} -> i === row end)
        expected_tent_count < 0 || length(row_tents) === expected_tent_count
      end

    Enum.all?(rows_match_expected_count, &(&1 === true))
  end

  @spec solution_satisfies_col_constraints?(
          solution :: [tent_placement],
          col_tent_count_map :: tent_count_map
        ) ::
          result :: boolean
  # Checks if the given solution fully satisfies all column constraints
  # We check the constraint for each column and put the results into a list
  # If each item in the list is true, the solution satisfies all column constraints
  defp solution_satisfies_col_constraints?(solution, col_tent_count_map) do
    columns_match_expected_count =
      for {col, expected_tent_count} <- col_tent_count_map do
        col_tents = solution |> Enum.filter(fn {_dir, {_i, j}} -> j === col end)
        expected_tent_count < 0 || length(col_tents) === expected_tent_count
      end

    Enum.all?(columns_match_expected_count, &(&1 === true))
  end
end
