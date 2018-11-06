defmodule BitcoinImplementationTest do
  use ExUnit.Case
  doctest BitcoinImplementation

  test "greets the world" do
    assert BitcoinImplementation.hello() == :world
  end
end
