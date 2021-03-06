defmodule Cryptex.Mcf do

  alias Cryptex.Mcf.Encoder

  @spec encode(Encoder.t) :: String.t
  def encode(kdf) do
    {name, data} = Encoder.encode(kdf)
    format(name, data)
  end

  defp format(name, data), do: "$#{name}$#{data}"

  defprotocol Encoder do

    def encode(kdf)

  end

end
