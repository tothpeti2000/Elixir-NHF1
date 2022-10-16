defmodule Khf3 do
  @moduledoc """
  Camping correctness
  
  @author "Tóth Péter tothpeti2000@edu.bme.hu"
  @date   "2022-10-05"
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

  # Numner of trees in teh camping
  @type cnt_tree :: integer
  # Number of elements in the tent direction list
  @type cnt_tent :: integer
  # The number of tents is incorrect in the given rows
  @type err_rows :: %{err_rows: [integer]}
  # The number of tents is incorrect in the given columns
  @type err_cols :: %{err_cols: [integer]}
  # The tents with the given coordinates touch another tent
  @type err_touch :: %{err_touch: [field]}
  # Tuple describing the puzzle errors
  @type errs_desc :: {err_rows, err_cols, err_touch}

  @spec check_sol(pd :: puzzle_desc, ds :: tent_dirs) :: ed :: errs_desc
  # We check the correctness of the puzzle solution based on the {rs, cs, ts} = pd puzzle description and the ds tent direction list, this gives us the ed error description
  #   rs ~ list of the expected tent count per row
  #   cs ~ list of the expected tent count per column
  #   ts ~ list of the tree coordintes
  # The elements of the {e_rows, e_cols, e_touch} = ed tuple are key-value pairs where the key describes the error type and the value is the list of the error places (empty if there are no errors)
  def check_sol({tents_count_rows, tents_count_cols, tree_fields}, directions) do
    tent_fields = get_tent_fields(tree_fields, directions)

    row_errors = get_row_errors(tents_count_rows, tent_fields)
    col_errors = get_col_errors(tents_count_cols, tent_fields)
    touch_errors = get_touch_errors(tent_fields)

    {row_errors, col_errors, touch_errors}
  end

  @spec get_tent_position(tree_field :: field, direction :: dir) :: tent_position :: field
  # Returns the position of a tent based on the position of its corresponding tree and the given direction
  defp get_tent_position({i, j}, :n), do: {i - 1, j}
  defp get_tent_position({i, j}, :e), do: {i, j + 1}
  defp get_tent_position({i, j}, :s), do: {i + 1, j}
  defp get_tent_position({i, j}, :w), do: {i, j - 1}

  @spec get_tent_fields(tree_fields :: [field], directions :: [dir]) :: [field]
  # Returns the positions of all tents based on all trees and the given directions
  defp get_tent_fields(_, []), do: []

  defp get_tent_fields(tree_fields, directions) do
    for(
      i <- 0..(length(tree_fields) - 1),
      do: get_tent_position(Enum.at(tree_fields, i), Enum.at(directions, i))
    )
    |> List.keysort(0)
  end

  @spec get_row_errors(tents_count_rows :: [Integer], tent_fields :: [field]) ::
          errors :: err_rows
  # Returns the row errors based on the expected row counts and the tent coordinates
  defp get_row_errors(tents_count_rows, tent_fields) do
    errors =
      for i <- 0..(length(tents_count_rows) - 1),
          has_row_error(i + 1, Enum.at(tents_count_rows, i), tent_fields) === :error,
          do: i + 1

    %{err_rows: errors}
  end

  @spec has_row_error(row :: Integer, expected_count :: Integer, tent_fields :: [field]) ::
          :ok | :error
  # Checks if a row contains the expected number of tents
  defp has_row_error(_, expected_count, _) when expected_count < 0, do: :ok

  defp has_row_error(row, expected_count, tent_fields) do
    actual_count = length(for {i, _} <- tent_fields, 0, i === row, do: i)

    cond do
      actual_count === expected_count -> :ok
      true -> :error
    end
  end

  @spec get_col_errors(tents_count_cols :: [Integer], tent_fields :: [field]) ::
          errors :: err_rows
  # Returns the col errors based on the expected col counts and the tent coordinates
  defp get_col_errors(tents_count_cols, tent_fields) do
    errors =
      for i <- 0..(length(tents_count_cols) - 1),
          has_col_error(i + 1, Enum.at(tents_count_cols, i), tent_fields) === :error,
          do: i + 1

    %{err_cols: errors}
  end

  @spec has_col_error(col :: Integer, expected_count :: Integer, tent_fields :: [field]) ::
          :ok | :error
  # Checks if a col contains the expected number of tents
  defp has_col_error(_, expected_count, _) when expected_count < 0, do: :ok

  defp has_col_error(col, expected_count, tent_fields) do
    actual_count = length(for {_, j} <- tent_fields, 0, j === col, do: j)

    cond do
      actual_count === expected_count -> :ok
      true -> :error
    end
  end

  @spec get_touch_errors(tent_fields :: [field]) :: errors :: err_touch
  # Returns the tents that touch each other based on the tent coordinates
  defp get_touch_errors(tent_fields) do
    errors =
      for {i1, j1} = field_1 <- tent_fields,
          {i2, j2} <- tent_fields -- [field_1],
          abs(i1 - i2) <= 1 && abs(j1 - j2) <= 1,
          do: {i1, j1}

    %{err_touch: Enum.uniq(errors)}
  end
end
