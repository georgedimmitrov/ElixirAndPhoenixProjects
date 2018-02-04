defmodule Identicon do
  def main(input) do
    input
    # %Identicon.Image{ color: nil, hex: [145, 46, 200, ..., 112]}
    |> hash_input
    # %Identicon.Image{ color: { 145, 46, 200 }, hex: [145, 46, 200, ..., 112]}
    |> pick_color
    # %Identicon.Image{ color: { 145, 46, 200}, hex: [145, 46, 200..], grid: [ { 145, 0}, {46, 1}, {200, 2}, {46, 3}, {145, 4}, ..., {} ]
    |> build_grid
    # %Identicon.Image{ color: { 145, 46, 200}, hex: [145, 46, 200..], grid: [ {46, 1}, { 200, 2}, {46, 3}] }
    |> filter_odd_squares
    # %Identicon.Image{ color: { 145, 46, 200}, hex: [145, 46, 200..], grid: [ {46, 1}, { 200, 2}, {46, 3}], pixel_map: [ {{50, 0}, {100, 50}}, {{...}}] }
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  def save_image(image, input) do
    File.write("#{input}.png", image)
  end

  def draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each pixel_map, fn({start, stop}) ->
      :egd.filledRectangle(image, start, stop, fill)
    end

    :egd.render(image)
  end

  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map = Enum.map grid, fn({_code, index}) ->
      horizontal = rem(index, 5) * 50
      vertical = div(index, 5) * 50

      top_left = {horizontal, vertical}
      bottom_right = {horizontal + 50, vertical + 50}

      {top_left, bottom_right}
    end

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  def filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    grid = Enum.filter grid, fn({code, _index}) ->
      # remainder - returns 0 if even number, 1 if odd number
      rem(code, 2) == 0
    end

    %Identicon.Image{image | grid: grid}
  end

  def build_grid(%Identicon.Image{hex: hex} = image) do
    grid =
      hex
      # [ [145, 46, 200], [3, 178, 206], ..., [x, y, z] ]
      |> Enum.chunk(3)
      # [ [145, 46, 200, 46, 145], [...], [x, y, z, y, x] ]
      |> Enum.map(&mirror_row/1)
      # [ 145, 46, 200, 46, 145, ..., x, y, z, y, x ]
      |> List.flatten
      # [ { 145, 0}, {46, 1}, {200, 2}, {46, 3}, {145, 4}, ..., {} ]
      |> Enum.with_index

    %Identicon.Image{ image | grid: grid}
  end

  def mirror_row(row) do
    # [145, 46, 200]
    [first, second | _tail] = row

    # [145, 46, 200, 46, 145]
    row ++ [second, first]
  end

  def pick_color(%Identicon.Image{hex: [r, g, b | _tail]} = image) do
    # Create entirely new struct with additinal property :color
    %Identicon.Image{image | color: {r, g, b}}
  end

  def hash_input(input) do
    hex = :crypto.hash(:md5, input)
    |> :binary.bin_to_list

    %Identicon.Image{hex: hex}
  end
end
