defmodule InterviewQuestionsTest do
  use ExUnit.Case
  doctest InterviewQuestions

  test "greets the world" do
    assert InterviewQuestions.hello() == :world
  end
end
