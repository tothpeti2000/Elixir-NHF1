defmodule Khf2 do
  @moduledoc """
  Camping map
  
  @author "Tóth Péter tothpeti2000@edu.bme.hu"
  @date   "2022-09-24"
  ...
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

  @spec to_external(pd :: puzzle_desc, directions :: tent_dirs, file :: String.t()) :: :ok
  # Prints the textual representation of the puzzle to the file based on the pd = {rs, cs, ts} puzzle description and the ds tent direction list
  #   rs: list of the tent counts per row
  #   cs: list of the tent counts per column
  #   ts: list of the coordinates of the fields which have a tree on them
  def to_external({tents_count_rows, tents_count_cols, tree_fields}, directions, file) do
    n = length(tents_count_rows)
    tent_fields = get_tent_fields(tree_fields, directions)

    # tents_count_rows = [1, 1, 0, 3, 0]
    # tents_count_cols = [1, 0, 2, 0, 2]
    # tree_fields = [{1, 2}, {3, 3}, {3, 5}, {5, 1}, {5, 5}]
    # tent_fields = [{{1, 3}, :e}, {{4, 3}, :s}, {{2, 5}, :n}, {{4, 1}, :n}, {{4, 5}, :n}]

    rows =
      for i <- 0..n,
          do: get_row(i, {tents_count_rows, tents_count_cols, tree_fields, tent_fields})

    lines = Enum.map(rows, fn row -> Enum.join(row, " ") end)

    file_content = Enum.join(lines, "\n")
    File.write!(file, file_content)
  end

  # Data about the position of a tent
  # field: which field the tent is on
  # dir: direction of the tent relative to its corresponding tree
  @type tent_data :: {field, dir}

  @spec get_tent_data(tree_field :: field, direction :: dir) :: tent_position_data :: tent_data
  # Returns data about a tent based on the position of its corresponding tree and the given direction
  defp get_tent_data({i, j}, :n), do: {{i - 1, j}, :n}
  defp get_tent_data({i, j}, :e), do: {{i, j + 1}, :e}
  defp get_tent_data({i, j}, :s), do: {{i + 1, j}, :s}
  defp get_tent_data({i, j}, :w), do: {{i, j - 1}, :w}

  @spec get_tent_fields(tree_fields :: [field], directions :: [dir]) :: [tent_data]
  # Returns data about all tents based on all trees and the given directions
  defp get_tent_fields(_, []), do: []

  defp get_tent_fields(tree_fields, directions) do
    for i <- 0..(length(tree_fields) - 1),
        do: get_tent_data(Enum.at(tree_fields, i), Enum.at(directions, i))
  end

  @spec get_row(
          i :: Integer,
          {tents_count_rows :: [Integer], tents_count_cols :: [Integer], tree_fields :: [field],
           tent_fields :: [tent_data]}
        ) :: row :: [any]
  # Returns the row with the given index in an array format based on the puzzle parameters
  # These rows will be converted to strings and joined together to create the output file content
  defp get_row(0, {_, tents_count_cols, _, _}), do: tents_count_cols

  defp get_row(i, {tents_count_rows, tents_count_cols, tree_fields, tent_fields}) do
    m = length(tents_count_cols)

    for j <- 0..m, do: get_row_item(i, j, {tents_count_rows, tree_fields, tent_fields})
  end

  @spec get_row_item(
          i :: Integer,
          j :: Integer,
          {tents_count_rows :: [Integer], tree_fields :: [field], tent_fields :: [tent_data]}
        ) :: row_item :: String
  # Returns a string representing an item in the output file content
  # This string can be the number of tents in a row, * if it's a tree field, N/E/S/W if it's a tent field or - if it's a regular field
  defp get_row_item(i, 0, {tents_count_rows, _, _}), do: Enum.at(tents_count_rows, i - 1)

  defp get_row_item(i, j, {_, tree_fields, tent_fields}) do
    cond do
      {i, j} in tree_fields -> "*"
      {{i, j}, :n} in tent_fields -> "N"
      {{i, j}, :e} in tent_fields -> "E"
      {{i, j}, :s} in tent_fields -> "S"
      {{i, j}, :w} in tent_fields -> "W"
      true -> "-"
    end
  end
end
