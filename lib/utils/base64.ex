# Based on the Elixir core implementation.
# https://github.com/elixir-lang/elixir/blob/bfd1c891c38a28d060d6bb094ef920b6e32c2cb6/lib/elixir/lib/base.ex
#
# Copyright (c) 2012 Plataformatec
# Released under the Apache License, Version 2.0. For more information, see the LICENSE file at the
# root of this project.

defmodule Cryptex.Utils.Base64 do

  use Bitwise

  defmacro __using__(opts) do
    alphabet = Keyword.fetch!(opts, :alphabet)
    default_padding = Keyword.get(opts, :padding, true)

    quote location: :keep do

      unquote do
        for {encoding, value} <- Enum.with_index(alphabet) do
          quote do
            defp encode_char(unquote(value)), do: unquote(encoding)
            defp decode_char(unquote(encoding)), do: unquote(value)
          end
        end
      end

      defp decode_char(c) do
        raise ArgumentError, "Non-alphabet digit found: #{inspect <<c>>, binaries: :as_strings} (byte #{c})"
      end

      def encode(data, opts \\ []) do
        opts = Keyword.put_new(opts, :padding, unquote(default_padding))
        Cryptex.Utils.Base64.encode(data, &encode_char/1, opts)
      end

      def decode!(data, opts \\ []) do
        opts = Keyword.put_new(opts, :padding, unquote(default_padding))
        Cryptex.Utils.Base64.decode!(data, &decode_char/1, opts)
      end

    end
  end

  def encode(data, encode_char, opts) do
    pad? = Keyword.get(opts, :padding, true)
    do_encode(data, encode_char, pad?)
  end

  def decode!(data, decode_char, opts) do
    pad? = Keyword.get(opts, :padding, true)
    do_decode(data, decode_char, pad?)
  end

  defp maybe_pad(subject, false, _, _), do: subject
  defp maybe_pad(subject, _, group_size, pad) do
    case rem(byte_size(subject), group_size) do
      0 -> subject
      x -> subject <> String.duplicate(pad, group_size - x)
    end
  end

  defp do_encode(<<>>, _, _), do: <<>>
  defp do_encode(data, encode_char, pad?) do
    split = 3 * div(byte_size(data), 3)
    <<main :: size(split)-binary, rest :: binary>> = data
    main = for <<c :: 6 <- main>>, into: <<>>, do: <<encode_char.(c) :: 8>>
    tail = case rest do
      <<c1 :: 6, c2 :: 6, c3 :: 4>> ->
        <<encode_char.(c1) :: 8, encode_char.(c2) :: 8, encode_char.(bsl(c3, 2)) :: 8>>
      <<c1 :: 6, c2 :: 2>> ->
        <<encode_char.(c1) :: 8, encode_char.(bsl(c2, 4)) :: 8>>
      <<>> -> <<>>
    end
    main <> maybe_pad(tail, pad?, 4, "=")
  end

  defp do_decode(<<>>, _, _), do: <<>>
  defp do_decode(string, decode_char, false) do
    maybe_pad(string, true, 4, "=") |> do_decode(decode_char, true)
  end
  defp do_decode(string, decode_char, _pad?) when rem(byte_size(string), 4) == 0 do
    split = byte_size(string) - 4
    <<main :: size(split)-binary, rest :: binary>> = string
    main = for <<c :: 8 <- main>>, into: <<>>, do: <<decode_char.(c) :: 6>>
    tail = case rest do
      <<c1 :: 8, c2 :: 8, ?=, ?=>> ->
        <<decode_char.(c1) :: 6, bsr(decode_char.(c2), 4) :: 2>>
      <<c1 :: 8, c2 :: 8, c3 :: 8, ?=>> ->
        <<decode_char.(c1) :: 6, decode_char.(c2) :: 6, bsr(decode_char.(c3), 2) :: 4>>
      <<c1 :: 8, c2 :: 8, c3 :: 8, c4 :: 8>> ->
        <<decode_char.(c1) :: 6, decode_char.(c2) :: 6, decode_char.(c3) :: 6, decode_char.(c4) :: 6>>
      <<>> -> <<>>
    end
    main <> tail
  end
  defp do_decode(_, _, _) do
      raise ArgumentError, "Invalid padding"
  end

end
