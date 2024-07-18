defmodule BingoServer do
  use GenServer

  # Client API
  def start_link() do
    GenServer.start_link(__MODULE__, %{})
  end

  def new_card(pid) do
    GenServer.call(pid, :new_card)
  end

  def fetch_card(pid, card_id) do
    GenServer.call(pid, {:fetch_card, card_id})
    # Get beingo card from state
  end

  def start_game do
    # reset state to start game
  end

  def restart_game do
    # Helper funtion that just calls start
  end

  def next_number do
    # fetch the next number and update state
  end

  def validate_win(_id) do
    # validate known bingo card wins the current game
  end

  # End Client API

  # Server
  def init(_) do
    {:ok, %{}}
  end


end

defmodule BingoCard do

  def new do
    IO.inspect("Generate A Bingo Card")
  end

end
