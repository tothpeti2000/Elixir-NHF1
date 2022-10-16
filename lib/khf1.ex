defmodule Khf1 do
  @moduledoc """
  Camping
  
  @author "Tóth Péter tothpeti2000@edu.bme.hu"
  @date   "2022-09-19"
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

  @spec to_internal(file :: String.t()) :: pd :: puzzle_desc
  # pd is the description of the puzzle stored in the file
  def to_internal(file) do
    rows = parse_file(file)

    row_tent_counts = first_items_of_arrays(tl(rows))
    col_tent_counts = hd(rows)
    tree_coordinates = get_tree_coordinates(rows)

    {row_tent_counts, col_tent_counts, tree_coordinates}
  end

  @type parsed_field_row :: [integer | [String]]
  @type parsed_file_content :: [[integer] | [parsed_field_row]]

  @spec parse_file(file :: String.t()) :: parsed :: parsed_file_content
  # parsed is the file content represented as an array of arrays where the numbers are converted to integers
  defp parse_file(file) do
    lines = File.read!(file) |> String.split(~r/\R/, trim: true)
    # [" 0  1 2     ", "0  - *  - ", "-1 *    -  *"]

    rows =
      lines
      |> Enum.map(fn text -> String.split(text) |> Enum.join(" ") end)
      |> Enum.filter(fn text -> text != "" end)

    # ["0 1 2", "0 - * -", "-1 * - *"]

    [first_row | other_rows] = Enum.map(rows, &String.split/1)
    # [["0", "1", "2"], ["0", "-", "*", "-"], ["-1", "*", "-", "*"]]

    parsed_first_row = Enum.map(first_row, &String.to_integer/1)

    parsed_other_rows =
      Enum.map(other_rows, fn [row_tents_count | fields] ->
        [String.to_integer(row_tents_count) | fields]
      end)

    [parsed_first_row | parsed_other_rows]
  end

  @spec first_items_of_arrays(arrays :: [[any]]) :: first_items :: [any]
  # Collect the first items of the arrays and put them into the first_items array
  defp first_items_of_arrays(arrays), do: Enum.map(arrays, &hd/1)

  @spec get_tree_coordinates(rows :: parsed_file_content) :: coordinates :: [field]
  # Get the coordinates of the trees from the rows and put them into the coordinates array
  defp get_tree_coordinates(rows) do
    n = length(rows) - 1
    m = length(hd(rows))

    for i <- 1..n, j <- 1..m, Enum.at(Enum.at(rows, i), j) == "*", do: {i, j}
  end
end
