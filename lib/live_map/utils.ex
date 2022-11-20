defmodule LiveMap.Utils do
  def parse_date(string_as_date) do
    string_as_date
    |> String.split("-")
    |> Enum.map(&String.to_integer/1)
    |> then(fn [y, m, d] ->
      Date.new!(y, m, d)
    end)
  end

  # def parse(d), do: d |> String.to_float()

  def string_to_float(d) when is_binary(d) do
    {res, _} = Float.parse(d)
    res
  end

  def perhaps_int(d) when is_binary(d) do
    d |> string_to_float |> round()
  end

  def perhaps_int(d) when is_float(d) do
    round(d)
  end

  def perhaps_int(d) when is_integer(d), do: d

  def safely_use(id), do: if(is_binary(id), do: String.to_integer(id), else: id)

  def to_km(d) do
    div1000 = fn x -> x / 1000 end
    d |> string_to_float() |> div1000.() |> round
  end
end
