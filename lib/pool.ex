defmodule Pool do
  use GenServer

  def start_link(args, opts) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  


end