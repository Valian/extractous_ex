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
    * `:max_length` - maximum length of extracted text in characters. Default is 500,000.
    * `:encoding` - encoding for text extraction. Supported values: "UTF-8" (default), "UTF-16BE", "US-ASCII".

  ## Examples

      # Extract plain text
      ExtractousEx.extract_from_file("document.pdf")
      {:ok, %{content: "Document text...", metadata: %{}}}

      # Extract as XML
      ExtractousEx.extract_from_file("document.html", xml: true)
      {:ok, %{content: "<html>...</html>", metadata: %{}}}

      # Extract with custom max length
      ExtractousEx.extract_from_file("large_document.pdf", max_length: 100_000)
      {:ok, %{content: "Truncated text...", metadata: %{}}}

      # Extract with specific encoding
      ExtractousEx.extract_from_file("document.txt", encoding: "UTF-16BE")
      {:ok, %{content: "Text with special chars...", metadata: %{}}}

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
    max_length = Keyword.get(opts, :max_length, nil)
    encoding = Keyword.get(opts, :encoding, nil)

    # Convert max_length to nil if not provided, otherwise ensure it's an integer
    max_length_opt = case max_length do
      nil -> nil
      val when is_integer(val) -> val
      _ -> raise ArgumentError, "max_length must be an integer"
    end

    # Convert encoding to nil if not provided, otherwise ensure it's a string
    encoding_opt = case encoding do
      nil -> nil
      val when is_binary(val) -> val
      _ -> raise ArgumentError, "encoding must be a string"
    end

    try do
      case Native.extract(file_path, xml, max_length_opt, encoding_opt) do
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
