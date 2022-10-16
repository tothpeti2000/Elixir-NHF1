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

  @spec satrak(pd :: puzzle_desc) :: tss :: [tent_dirs]
  # tss is the list of all solutions of the puzzle described by pd in an arbitrary order
  def satrak({_tents_count_rows, _tents_count_cols, []}), do: []

  def satrak({tents_count_rows, tents_count_cols, trees}) do
    row_count = length(tents_count_rows)
    col_count = length(tents_count_cols)

    initial_map = init_tree_tent_map(trees)
    tree_tent_map = fill_map_with_possible_tent_fields(initial_map, row_count, col_count)

    find_solutions(tree_tent_map, tents_count_rows, tents_count_cols)
    |> Enum.map(fn solution -> Enum.map(solution, fn {dir, _tent_field} -> dir end) end)
  end

  @type tree_tent_map :: %{field => []}

  @spec init_tree_tent_map(trees :: trees) :: initial_map :: tree_tent_map
  # Initializes a map where the keys are the tree fields in the puzzle description and the values are empty lists
  defp init_tree_tent_map(trees) do
    for tree <- trees, into: %{}, do: {tree, []}
  end

  @spec fill_map_with_possible_tent_fields(
          map :: tree_tent_map,
          row_count :: integer,
          col_count :: integer
        ) ::
          filled_map :: tree_tent_map
  # Creates a tent-tree map where the value of each key is a list of all possible tent fields of the corresponding tree
  defp fill_map_with_possible_tent_fields(map, row_count, col_count) do
    for {tree, _value} <- map,
        into: %{},
        do: {tree, get_tree_neighbors(tree, row_count, col_count, map)}
  end

  @spec get_tree_neighbors(
          tree :: field,
          row_count :: integer,
          col_count :: integer,
          map :: tree_tent_map
        ) :: [{dir, [field]}]
  # Returns all possible tent fields of a tree considering the row count and column count in the puzzle description
  defp get_tree_neighbors(tree, row_count, col_count, map) do
    for direction <- [:n, :e, :s, :w],
        (result = get_tree_neighbor(tree, direction, row_count, col_count, map)) !== nil,
        do: {direction, result}
  end

  @spec get_tree_neighbor(
          tree :: field,
          direction :: dir,
          row_count :: integer,
          col_count :: integer,
          map :: tree_tent_map
        ) :: result :: field | nil
  # Returns the tent of a tree in the given direction
  # If the neighbor field is out of bounds or there's a tree on it, we return nil to indicate it
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

  @type solution :: {dir, field}

  @spec find_solutions(
          tree_tent_map :: tree_tent_map,
          tents_count_rows :: [integer],
          tents_count_cols :: [integer]
        ) :: solutions :: [solution]
  # Finds all solutions of the puzzle using backtracking
  # We collect the solutions in an accumulator which is an empty list initially
  defp find_solutions(tree_tent_map, tents_count_rows, tents_count_cols),
    do: find_solutions(tree_tent_map, tents_count_rows, tents_count_cols, [])

  @spec find_solutions(
          tree_tent_map :: tree_tent_map,
          tents_count_rows :: [integer],
          tents_count_cols :: [integer],
          tents :: [solution]
        ) :: solutions :: [solution]
  # When we reach a leaf of the state space tree created by backtracking, we check if the solution satisfies the row and column constraints
  # This is important because otherwise even those solutions would be marked valid which don't reach the minimum row or column tent count
  defp find_solutions(tree_tent_map, tents_count_rows, tents_count_cols, tents)
       when map_size(tree_tent_map) === 0 do
    if solution_satisfies_row_constraint?(tents, tents_count_rows) &&
         solution_satisfies_col_constraint?(tents, tents_count_cols),
       do: [tents],
       else: nil
  end

  # Recursively collect each solution of the puzzle using backtracking
  # In each iteration, we take the first tree of the tree-tent map
  # For each possible tent field, we check if picking that tent is a valid choice
  # If it doesn't violate any puzzle constraint, we pick that tent and drop its corresponding tree from the map
  # Otherwise, we terminate that branch since it's not a valid placement
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

  @spec violates_row_constraint?(
          tree :: field,
          tents_so_far :: [solution],
          tents_count_rows :: [integer]
        ) :: result :: boolean
  # Checks if choosing the given tent results in exceeding the tent count limit of its row
  defp violates_row_constraint?({i, _j}, tents_so_far, tents_count_rows) do
    expected_row_count = Enum.at(tents_count_rows, i - 1)
    row_tents_so_far = tents_so_far |> Enum.filter(fn {_dir, {a, _b}} -> a === i end)

    expected_row_count >= 0 && length(row_tents_so_far) + 1 > expected_row_count
  end

  @spec violates_col_constraint?(
          tree :: field,
          tents_so_far :: [solution],
          tents_count_cols :: [integer]
        ) :: result :: boolean
  # Checks if choosing the given tent results in exceeding the tent count limit of its column
  defp violates_col_constraint?({_i, j}, tents_so_far, tents_count_cols) do
    expected_col_count = Enum.at(tents_count_cols, j - 1)
    col_tents_so_far = tents_so_far |> Enum.filter(fn {_dir, {_a, b}} -> b === j end)

    expected_col_count >= 0 && length(col_tents_so_far) + 1 > expected_col_count
  end

  @spec touches_other_tent?(
          tree :: field,
          tents_so_far :: [solution]
        ) :: result :: boolean
  # Checks if choosing the given tent results in a touch error
  defp touches_other_tent?({i, j}, tents_so_far) do
    Enum.any?(tents_so_far, fn {_dir, {a, b}} -> abs(a - i) <= 1 && abs(b - j) <= 1 end)
  end

  @spec solution_satisfies_row_constraint?(solution :: [solution], tents_count_rows :: [integer]) ::
          result :: boolean
  # Checks if the given solution fully satisfies all row constraints
  defp solution_satisfies_row_constraint?(solution, tents_count_rows) do
    matches =
      for i <- 0..(length(tents_count_rows) - 1) do
        tents_count_row = Enum.at(tents_count_rows, i)

        row_tents = solution |> Enum.filter(fn {_dir, {a, _j}} -> a === i + 1 end)
        tents_count_row < 0 || length(row_tents) === tents_count_row
      end

    Enum.all?(matches, fn item -> item === true end)
  end

  @spec solution_satisfies_col_constraint?(solution :: [solution], tents_count_cols :: [integer]) ::
          result :: boolean
  # Checks if the given solution fully satisfies all column constraints
  defp solution_satisfies_col_constraint?(solution, tents_count_cols) do
    matches =
      for i <- 0..(length(tents_count_cols) - 1) do
        tents_count_col = Enum.at(tents_count_cols, i)

        col_tents = solution |> Enum.filter(fn {_dir, {_a, b}} -> b === i + 1 end)
        tents_count_col < 0 || length(col_tents) === tents_count_col
      end

    Enum.all?(matches, fn item -> item === true end)
  end
end
