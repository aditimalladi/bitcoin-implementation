defmodule User do
  use GenServer

  def start_link(args, opts) do
    GenServer.start_link(__MODULE__, args, opts)
  end
  
  def init({:genesis, block-data, difficulty}) do
    {public-key, private-key} = :crypto.generate_key(:rsa, {256, 17})
    {:ok, %{:difficulty => difficulty, :private-key => private-key, :public-key => public-key}}
  end


end

