defmodule Romeo.Error do
  defexception [:message]

  def exception(message) do
    %Romeo.Error{message: translate_message(message)}
  end

  defp translate_message({:timeout, ms, connection_step}) do
    step = translate_connection_step(connection_step)
    secs = ms / 1_000
    "Failed to #{step} after #{secs} seconds."
  end
  defp translate_message(message), do: inspect(message)

  defp translate_connection_step(atom) do
    Atom.to_string(atom) |> String.replace("_", " ")
  end
end
