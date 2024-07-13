defmodule FizzBuzz do
  def run(num \\ 1000) do
    Enum.each(1..num, fn value ->
      cond do
        rem(value, 5) == 0 and rem(value, 3) == 0 ->
          IO.puts("FizzBuzz")
        rem(value, 3) === 0 ->
          IO.puts("Fizz")
        rem(value, 5) === 0 ->
          IO.puts("Buzz")
        value ->
          IO.puts(value)
      end
    end)
  end
end
