defmodule BingoServer do
  use GenServer

  # Client API
  def start_link() do
    GenServer.start_link(__MODULE__, %{game: %{}, cards: %{}, next_card_id: 1})
  end

  def new_card(pid) do
    GenServer.call(pid, :new_card)
  end

  def fetch_card(pid, card_id) do
    GenServer.call(pid, {:fetch_card, card_id})
  end

  def start_game(pid) do
    GenServer.cast(pid, :start_game)
  end

  def draw_number(pid) do
    GenServer.call(pid, :draw_number)
  end

  def validate_win(pid, card_id) do
    GenServer.call(pid, {:validate_card, card_id})
  end

  # End Client API

  # Server
  def init(default_state) do
    {:ok, default_state}
  end

  def handle_call({:fetch_card, card_id}, _from, state) do
    {:reply, card_id, state}
  end

  def handle_call(:new_card, _from, %{next_card_id: next_card_id, cards: old_cards} = state) do
    new_card = BingoCard.new()
    new_cards = Map.put(old_cards, next_card_id, new_card)
    {:reply, new_card, %{state | cards: new_cards, next_card_id: next_card_id + 1}}
  end

  def handle_call(:draw_number, _from, state) do
    {number, updated_game} = BingoGame.draw_number(state.game)
    {:reply, number, %{state | game: updated_game}}
  end

  def handle_call({:validate_card, card_id}, _from, %{cards: cards, game: game} = state) do
    card = Map.get(cards, card_id)
    case BingoGame.validate_card(game, card) do
      true -> {:reply, "WINNER!", state}
      _ -> {:reply, "Card is not a winner!", state}
    end
  end

  def handle_cast(:start_game, state) do
    game = BingoGame.new()
    {:noreply, %{state | game: game}}
  end
end

defmodule BingoCard do
  defstruct id: "", card: %{}

  def new do
    b_row = generate_row(5, 1..15)
    i_row = generate_row(5, 16..30)
    n_row = generate_row(4, 31..45)
    g_row = generate_row(5, 46..60)
    o_row = generate_row(5, 61..75)
    %BingoCard{
      id: generate_id([b_row, i_row, n_row, g_row, o_row]),
      card: %{
        "B" => b_row,
        "I" => i_row,
        "N" => n_row,
        "G" => g_row,
        "O" => o_row,
      }
    }
  end

  defp generate_id(rows) do
    rows |> Enum.map(&Enum.join(&1, "")) |> Enum.join("")
  end

  defp generate_row(number_count, range) do
    do_generate_row(number_count, Enum.to_list(range), [])
  end

  defp do_generate_row(0, _, acc), do: acc
  defp do_generate_row(number_count, list, acc) do
    random_number = :rand.uniform(Kernel.length(list) - 1)
    {next_num, remaining_list} = List.pop_at(list, random_number)
    next_num = next_num |> Integer.to_string() |> String.pad_leading(2, "0")
    do_generate_row(number_count - 1, remaining_list, [next_num | acc])
  end
end

defmodule BingoGame do
  def new do
    %{
      number_pool: generate_number_pool(),
      drawn_numbers: []
    }
  end

  def draw_number(%{number_pool: []} = game) do
    {:error, game}
  end
  def draw_number(%{number_pool: [number], drawn_numbers: drawn_numbers}) do
    {number, %{number_pool: [], drawn_numbers: [number | drawn_numbers]}}
  end
  def draw_number(game) do
    rand_number = :rand.uniform(Kernel.length(game.number_pool) - 1)
    {number, new_pool} = List.pop_at(game.number_pool, rand_number)
    {number, %{number_pool: new_pool, drawn_numbers: [number | game.drawn_numbers]}}
  end

  defp generate_number_pool do
    do_generate_number_pool(75, [])
  end

  defp do_generate_number_pool(0, acc), do: acc
  defp do_generate_number_pool(number, acc) do
    ball = number_to_letter(number) <> String.pad_leading(Integer.to_string(number), 2, "0")
    do_generate_number_pool(number - 1, [ball | acc])
  end

  defp number_to_letter(number) do
    cond do
      number <= 75 && number >= 61 -> "O"
      number <= 60 && number >= 46 -> "G"
      number <= 45 && number >= 31 -> "N"
      number <= 30 && number >= 16 -> "I"
      true -> "B"
    end
  end

  def validate_card(game, card) do
    bingo_keys = ["B", "I", "N", "G", "O"]
    marked_card = Enum.reduce(bingo_keys, %{}, fn key, acc ->
      row = Map.get(card.card, key)
      new_row = Enum.map(row, fn cell_value ->
        case Enum.member?(game.drawn_numbers, key <> cell_value) do
           true -> "XX"
           false -> cell_value
        end
      end)
      Map.put(acc, key, new_row)
    end)
    is_winning_card?(marked_card)
  end

  defp is_winning_card?(%{"B" => ["XX", "XX", "XX", "XX", "XX"]}), do: true
  defp is_winning_card?(%{"I" => ["XX", "XX", "XX", "XX", "XX"]}), do: true
  defp is_winning_card?(%{"N" => ["XX", "XX", "XX", "XX"]}), do: true
  defp is_winning_card?(%{"G" => ["XX", "XX", "XX", "XX", "XX"]}), do: true
  defp is_winning_card?(%{"O" => ["XX", "XX", "XX", "XX", "XX"]}), do: true
  defp is_winning_card?(%{"B" => ["XX" | _], "I" => ["XX" | _], "N" => ["XX" | _], "G" => ["XX" | _], "O" => ["XX" | _],}), do: true
  defp is_winning_card?(%{"B" => [_, "XX" | _], "I" => [_, "XX" | _], "N" => [_, "XX" | _], "G" => [_, "XX" | _], "O" => [_, "XX" | _],}), do: true
  defp is_winning_card?(%{"B" => [_, _, "XX" | _], "I" => [_, _, "XX" | _], "G" => [_, _, "XX" | _], "O" => [_, _, "XX" | _],}), do: true
  defp is_winning_card?(%{"B" => [_, _, _, "XX" | _], "I" => [_, _, _, "XX" | _], "N" => [_, _, "XX" | _], "G" => [_, _, _, "XX" | _], "O" => [_, _, _, "XX" | _],}), do: true
  defp is_winning_card?(%{"B" => [_, _, _, _, "XX"], "I" => [_, _, _, _, "XX"], "N" => [_, _, _, "XX"], "G" => [_, _, _, _, "XX"], "O" => [_, _, _, _, "XX"],}), do: true
  defp is_winning_card?(%{"B" => ["XX" | _], "I" => [_, "XX" | _], "G" => [_, _, _, "XX" | _], "O" => [_, _, _, _, "XX"],}), do: true
  defp is_winning_card?(%{"O" => ["XX" | _], "G" => [_, "XX" | _], "I" => [_, _, _, "XX" | _], "B" => [_, _, _, _, "XX"],}), do: true

  defp is_winning_card?(_), do: false
end
