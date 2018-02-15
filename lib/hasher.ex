defmodule Cryptex.Hasher do

  alias Cryptex.Hasher
  alias Cryptex.Hasher.State

  @type algorithm :: Cryptex.Hasher.Algorithm.t | atom

  defstruct module: nil, opts: []
  @type t :: %__MODULE__{module: Cryptex.Hasher.Algorithm.t, opts: Keyword.t}

  @spec new(algorithm, Keyword.t) :: t
  def new(module, opts \\ []) do
    resolved_module = resolve_module(module)
    %Hasher{module: resolved_module, opts: opts}
  end

  @spec new_state(t) :: State.t
  def new_state(%Hasher{module: module, opts: opts}) do
    State.new(module, opts)
  end

  @spec new_state(algorithm, Keyword.t) :: State.t
  def new_state(module, opts \\ []) do
    new(module, opts) |> new_state
  end

  @spec digest(t | algorithm, State.digestable) :: binary
  def digest(hasher_or_module, data)
  def digest(%Hasher{module: module, opts: opts}, data) do
    State.new(module, opts) |> State.update(data) |> State.digest
  end
  def digest(module, data) do
    new(module) |> digest(data)
  end

  @spec block_size(t) :: integer
  def block_size(%Hasher{module: module}), do: module.block_size

  @spec digest_size(t) :: integer
  def digest_size(%Hasher{module: module}), do: module.digest_size

  @spec name(t) :: String.t
  def name(%Hasher{module: module}), do: module.name

  @spec camelize(String.t()) :: String.t()
  def camelize(string)

  def camelize(""), do: ""
  def camelize(<<?_, t::binary>>), do: camelize(t)
  def camelize(<<h, t::binary>>), do: <<to_upper_char(h)>> <> do_camelize(t)

  defp do_camelize(<<?_, ?_, t::binary>>), do: do_camelize(<<?_, t::binary>>)

  defp do_camelize(<<?_, h, t::binary>>) when h >= ?a and h <= ?z,
    do: <<to_upper_char(h)>> <> do_camelize(t)

  defp do_camelize(<<?_, h, t::binary>>) when h >= ?0 and h <= ?9, do: <<h>> <> do_camelize(t)
  defp do_camelize(<<?_>>), do: <<>>
  defp do_camelize(<<?/, t::binary>>), do: <<?.>> <> camelize(t)
  defp do_camelize(<<h, t::binary>>), do: <<h>> <> do_camelize(t)
  defp do_camelize(<<>>), do: <<>>

  defp to_upper_char(char) when char >= ?a and char <= ?z, do: char - 32
  defp to_upper_char(char), do: char

  defp to_lower_char(char) when char >= ?A and char <= ?Z, do: char + 32
  defp to_lower_char(char), do: char
  
  defp resolve_module(module) do
    case Atom.to_string(module) do
      "Elixir." <> _ -> module
      reference -> Module.concat(__MODULE__.Algorithm, camelize(reference))
    end
  end

end
