defmodule DataStore do
  @moduledoc """
  Let's Go Bowling, has 2 objectives

  Objective 1:
  We got the data for 2 teams in a local bowling league.
  The data comes in in 2 responses. One, assigned scores contains the scoring data and userid. The other, assigned players contains information about the users.
  Aggregate the data and find out which team won. Winning is defined by the team with the highest average score.

  Bonus:
  Each score includes a timestamp. Sometimes a score will come in for a round on a previous day. Assume the games are all played in UTC -6 and exclude any scores not from May 13, 2021.

  Objective 2:
  One of the players, Noah, appealed to the league office and his score was changed. They sent over his new score, assigned noahs_updated_scorecard.
  We need to calculate the new score and find out who won.
  The format for a text score is:

  - Strikes are denoted with "X"
  - Spares are denoted with "\n" where "n" is the number of pins knocked down in the first half of the frame.
  - Splits are noted with a "S" followed by the number of pins knocked down in each half of the frame
  - Open frames are noted as the pins for each half of that frame.

  """

  @scores """
  [
    {
      "datetime": 1620893521,
      "score": 235,
      "userid": "1ef9a302-6b0d-4c49-8170-87a8129518a7"
    },
    {
      "datetime": 1620894521,
      "score": 280,
      "userid": "ad70c24c-74cf-48c3-b80f-0e28e18551b8"
    },
    {
      "datetime": 1620895521,
      "score": 290,
      "userid": "4594dc0f-384a-4770-8e95-2ef9261e5fa7"
    },
    {
      "datetime": 1620896521,
      "score": 230,
      "userid": "3e24e48e-b9c4-46bb-af20-2cb8e3dc4478"
    },
    {
      "datetime": 1620897521,
      "score": 290,
      "userid": "b7e7079a-6e1d-43b0-8123-cc5e00599331"
    },
    {
      "datetime": 1620898521,
      "score": 210,
      "userid": "1a01e570-805d-44e6-bc1a-4882a40ee54f"
    },
    {
      "datetime": 1620899521,
      "score": 280,
      "userid": "e19f4884-63a8-44fc-bc0e-3b206d6f8f62"
    },
    {
      "datetime": 1620900521,
      "score": 295,
      "userid": "62c6a5f2-57fd-48b6-b545-7c2c89c17a92"
    },
    {
      "datetime": 1620901521,
      "score": 190,
      "userid": "38ab2cbb-b9c2-41b3-9a21-2e92fc7c61d5"
    },
    {
      "datetime": 1620902521,
      "score": 275,
      "userid": "5e44f883-6d78-4c23-92c0-7bb3d157e9a9"
    }
  ]
  """

  @players """
  [
    {
      "name": "Liam",
      "teamid": "2eb3f470-b4bc-11eb-8529-0242ac130003",
      "userid": "1ef9a302-6b0d-4c49-8170-87a8129518a7"
    },
    {
      "name": "Sophia",
      "teamid": "d7a32056-8c14-4ee3-b465-77a8bc2b8486",
      "userid": "ad70c24c-74cf-48c3-b80f-0e28e18551b8"
    },
    {
      "name": "Isabella",
      "teamid": "2eb3f470-b4bc-11eb-8529-0242ac130003",
      "userid": "4594dc0f-384a-4770-8e95-2ef9261e5fa7"
    },
    {
      "name": "William",
      "teamid": "d7a32056-8c14-4ee3-b465-77a8bc2b8486",
      "userid": "3e24e48e-b9c4-46bb-af20-2cb8e3dc4478"
    },
    {
      "name": "Emma",
      "teamid": "2eb3f470-b4bc-11eb-8529-0242ac130003",
      "userid": "b7e7079a-6e1d-43b0-8123-cc5e00599331"
    },
    {
      "name": "James",
      "teamid": "d7a32056-8c14-4ee3-b465-77a8bc2b8486",
      "userid": "1a01e570-805d-44e6-bc1a-4882a40ee54f"
    },
    {
      "name": "Noah",
      "teamid": "2eb3f470-b4bc-11eb-8529-0242ac130003",
      "userid": "e19f4884-63a8-44fc-bc0e-3b206d6f8f62"
    },
    {
      "name": "Olivia",
      "teamid": "d7a32056-8c14-4ee3-b465-77a8bc2b8486",
      "userid": "62c6a5f2-57fd-48b6-b545-7c2c89c17a92"
    },
    {
      "name": "Oliver",
      "teamid": "2eb3f470-b4bc-11eb-8529-0242ac130003",
      "userid": "38ab2cbb-b9c2-41b3-9a21-2e92fc7c61d5"
    },
    {
      "name": "Ava",
      "teamid": "d7a32056-8c14-4ee3-b465-77a8bc2b8486",
      "userid": "5e44f883-6d78-4c23-92c0-7bb3d157e9a9"
    }
  ]

  """

  @noahs_updated_scorecard "XX\\9X\\3S80XX81XXX"

  def scores, do: @scores
  def players, do: @players
  def noahs_updated_scorecard, do: @noahs_updated_scorecard

  defp do_user_to_team_map(players_json) do
    Enum.reduce(players_json, %{}, fn player, acc ->
      Map.put(acc, player.userid, player.teamid)
    end)
  end

  defp do_team_score_map(user_to_team_map, filter_date \\ nil) do
    scores_json = Jason.decode!(DataStore.scores(), keys: :atoms)

    Enum.reduce(scores_json, %{}, fn score, acc ->
      teamid = Map.get(user_to_team_map, score.userid)
      score_date_time = DateTime.from_unix!(score.datetime)

      if filter_date === nil || filter_date === DateTime.to_date(score_date_time) do
        Map.update(acc, teamid, {score.score, 1}, fn {total_score, score_count} ->
          {total_score + score.score, score_count + 1}
        end)
      else
        acc
      end
    end)
  end

  @doc """
  Averages each teams score, and finds the total highest score and teamid
  """
  defp find_winning_team(team_score_map) do
    Enum.reduce(team_score_map, {"", 0}, fn {teamid, {total_score, score_count}},
                                            {_old_teamid, old_score} = acc ->
      if div(total_score, score_count) > old_score do
        {teamid, div(total_score, score_count)}
      else
        acc
      end
    end)
  end

  def calculate do
    players_json = Jason.decode!(DataStore.players(), keys: :atoms)

    {winning_teamid, _winning_score} =
      players_json |> do_user_to_team_map() |> do_team_score_map() |> find_winning_team()

    winning_teamid
  end

  def calculate_bonus do
    # goal remove any scores not from target ~D[2021, 05, 13]
    players_json = Jason.decode!(DataStore.players(), keys: :atoms)

    {winning_teamid, _winning_score} =
      players_json
      |> do_user_to_team_map()
      |> do_team_score_map(~D[2021-05-13])
      |> find_winning_team()

    winning_teamid
  end

  # X X \9 X \3 S80 X X 81 X X X
  # 201

  defp ascii_to_number(ascii_code), do: ascii_code - 48

  defp calculate_score(<<"X", "X", "X">>, acc) do
    acc + 10 + 10 + 10
  end

  defp calculate_score(<<"X", "X", "X", rest::binary>>, acc) do
    calculate_score("X" <> "X" <> rest, acc + 10 + 10 + 10)
  end

  defp calculate_score(<<"X", "X", "\\", first_throw::8, rest::binary>>, acc) do
    score = 10 + 10 + ascii_to_number(first_throw)
    calculate_score("X" <> "\\" <> List.to_string([first_throw]) <> rest, acc + score)
  end

  defp calculate_score(<<"X", "X", first_throw::8, rest::binary>>, acc) do
    score = 10 + 10 + ascii_to_number(first_throw)
    calculate_score("X" <> List.to_string([first_throw]) <> rest, acc + score)
  end

  defp calculate_score(<<"X", "\\", rest::binary>>, acc) do
    calculate_score("\\" <> rest, acc + 10 + 10)
  end

  defp calculate_score(<<"X", first_throw::8, second_throw::8, rest::binary>>, acc) do
    score = 10 + ascii_to_number(first_throw) + ascii_to_number(second_throw)

    calculate_score(
      List.to_string([first_throw]) <> List.to_string([second_throw]) <> rest,
      acc + score
    )
  end

  defp calculate_score(<<"\\", _::8, "X", rest::binary>>, acc) do
    calculate_score("X" <> rest, acc + 10 + 10)
  end

  # TODO handle \8 \9

  defp calculate_score(<<"\\", _::8, "S", next_throw::8, rest::binary>>, acc) do
    score = 10 + ascii_to_number(next_throw)
    calculate_score("S" <> List.to_string([next_throw]) <> rest, acc + score)
  end

  defp calculate_score(<<"\\", _::8, next_throw::8, rest::binary>>, acc) do
    score = 10 + ascii_to_number(next_throw)
    calculate_score(List.to_string([next_throw]) <> rest, acc + score)
  end

  defp calculate_score(<<"S", first_throw::8, second_throw::8, rest::binary>>, acc) do
    score = ascii_to_number(first_throw) + ascii_to_number(second_throw)
    calculate_score(rest, acc + score)
  end

  defp calculate_score(<<"X">>, acc) do
    calculate_score("", acc + 10)
  end

  defp calculate_score(<<"X", rest::binary>>, acc) do
    calculate_score(rest, acc + 10)
  end

  defp calculate_score(<<first_throw::8, second_throw::8, rest::binary>>, acc) do
    score = ascii_to_number(first_throw) + ascii_to_number(second_throw)
    IO.inspect(score + acc)
    calculate_score(rest, acc + score)
  end

  defp calculate_score("", acc) do
    acc
  end

  def calculate_with_new_score do
    score = calculate_score(noahs_updated_scorecard(), 0)
  end
end
