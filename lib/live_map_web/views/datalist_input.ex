defmodule LiveMapWeb.InputHelpers do
  use Phoenix.HTML

  def datalist_input(opts, [do: _] = block_options) do
    content_tag(:datalist, opts, block_options)
  end

  def option_input(user) do
    content_tag(:option, "", value: user)
  end
end
