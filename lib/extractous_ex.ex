defmodule ExtractousEx do
  @moduledoc """
  ExtractousEx provides text extraction from various document formats using the Extractous Rust library.

  Supports PDF, Microsoft Office documents, HTML, plain text, CSV, JSON, and many other formats.
  """

  alias ExtractousEx.Native

  @doc """
  Extracts text and metadata from a file.

  ## Options

    * `:xml` - when `true`, returns structured XML output. When `false` (default), returns plain text.

  ## Examples

      # Extract plain text
      ExtractousEx.extract_from_file("document.pdf")
      {:ok, %{content: "Document text...", metadata: %{}}}

      # Extract as XML
      ExtractousEx.extract_from_file("document.html", xml: true)
      {:ok, %{content: "<html>...</html>", metadata: %{}}}

  ## Returns

  Returns `{:ok, result}` on success where `result` is a map with:
    * `:content` - The extracted text content
    * `:metadata` - Document metadata as a map

  Returns `{:error, reason}` on failure.
  """
  @spec extract_from_file(String.t(), keyword()) ::
          {:ok, %{content: String.t(), metadata: map()}} | {:error, String.t()}
  def extract_from_file(file_path, opts \\ []) do
    xml = Keyword.get(opts, :xml, false)

    try do
      case Native.extract(file_path, xml) do
        {content, metadata_string} when is_binary(content) and is_binary(metadata_string) ->
          metadata =
            case Jason.decode(metadata_string) do
              {:ok, parsed_metadata} -> parsed_metadata
              {:error, _} -> %{}
            end

          {:ok, %{content: content, metadata: metadata}}

        {:error, reason} ->
          {:error, reason}

        other ->
          {:error, "Unexpected response: #{inspect(other)}"}
      end
    rescue
      error -> {:error, Exception.message(error)}
    end
  end

  @doc """
  Extracts text from a file, raising on error.

  Same as `extract_from_file/2` but raises an exception on failure.

  ## Examples

      ExtractousEx.extract_from_file!("document.pdf")
      %{content: "Document text...", metadata: %{}}

  """
  @spec extract_from_file!(String.t(), keyword()) :: %{content: String.t(), metadata: map()}
  def extract_from_file!(file_path, opts \\ []) do
    case extract_from_file(file_path, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise "Failed to extract from #{file_path}: #{inspect(reason)}"
    end
  end
end
