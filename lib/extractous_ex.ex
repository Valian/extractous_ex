defmodule ExtractousEx do
  @moduledoc """
  ExtractousEx provides text extraction from various document formats using the Extractous Rust library.

  Supports PDF, Microsoft Office documents, HTML, plain text, CSV, JSON, and many other formats.

  ## Extraction Methods

  * `extract_from_file/2` - Extract text from a file on disk
  * `extract_from_bytes/2` - Extract text from binary data in memory
  * `extract_from_url/2` - Extract text from a URL

  Each method has a corresponding bang version (e.g., `extract_from_file!/2`) that raises on error.

  ## Options

  All extraction methods accept a keyword list of options:

  ### General options (top-level):
  * `:xml` - when `true`, returns structured XML output. When `false` (default), returns plain text.
  * `:max_length` - maximum length of extracted text in characters. Default is 500,000.
  * `:encoding` - encoding for text extraction. Supported values: "UTF-8" (default), "UTF-16BE", "US-ASCII".

  ### PDF options (under `:pdf` key):
  * `:ocr_strategy` - "NO_OCR", "AUTO", "OCR_ONLY", or "OCR_AND_TEXT_EXTRACTION"
  * `:extract_annotation_text` - extract text from PDF annotations
  * `:extract_inline_images` - extract inline images
  * `:extract_unique_inline_images_only` - extract only unique inline images
  * `:extract_marked_content` - extract marked content

  ### Office options (under `:office` key):
  * `:include_shape_based_content` - include shape-based content
  * `:include_slide_notes` - include slide notes
  * `:include_slide_master_content` - include slide master content
  * `:concatenate_phonetic_runs` - concatenate phonetic runs
  * `:include_headers_and_footers` - include headers and footers
  * `:include_deleted_content` - include deleted content
  * `:include_move_from_content` - include move-from content
  * `:include_missing_rows` - include missing rows
  * `:extract_macros` - extract macros
  * `:extract_all_alternatives_from_msg` - extract all alternatives from MSG files

  ### OCR options (under `:ocr` key):
  * `:language` - Tesseract language (e.g., "eng", "deu", "eng+deu")
  * `:timeout_seconds` - OCR timeout in seconds
  * `:density` - image density for OCR
  * `:depth` - image depth for OCR
  * `:apply_rotation` - apply rotation during OCR
  * `:enable_image_preprocessing` - enable image preprocessing for OCR

  ## Examples

      # Simple usage
      ExtractousEx.extract_from_file("document.pdf")
      {:ok, %{content: "Document text...", metadata: %{}}}

      # With basic options
      ExtractousEx.extract_from_file("document.pdf", xml: true, max_length: 100_000)
      {:ok, %{content: "<xml>...</xml>", metadata: %{}}}

      # With advanced options
      ExtractousEx.extract_from_file("document.pdf",
        max_length: 1_000_000,
        xml: true,
        pdf: [
          ocr_strategy: "AUTO",
          extract_annotation_text: true
        ],
        ocr: [
          language: "eng+deu",
          timeout_seconds: 60
        ]
      )
      {:ok, %{content: "Document text...", metadata: %{}}}

  """

  alias ExtractousEx.Native

  @doc """
  Extracts text and metadata from a file.

  ## Options

  Accepts a keyword list of options. See module documentation for full details.

  ## Examples

      # Simple usage
      ExtractousEx.extract_from_file("document.pdf")
      {:ok, %{content: "Document text...", metadata: %{}}}

      # With options
      ExtractousEx.extract_from_file("document.pdf", xml: true)
      {:ok, %{content: "<xml>...</xml>", metadata: %{}}}

      # With nested options
      ExtractousEx.extract_from_file("document.pdf",
        xml: true,
        pdf: [ocr_strategy: "NO_OCR"]
      )
      {:ok, %{content: "Document text...", metadata: %{}}}

  ## Returns

  Returns `{:ok, result}` on success where `result` is a map with:
    * `:content` - The extracted text content
    * `:metadata` - Document metadata as a map

  Returns `{:error, reason}` on failure.
  """
  @spec extract_from_file(String.t(), keyword()) ::
          {:ok, %{content: String.t(), metadata: map()}} | {:error, String.t()}
  def extract_from_file(file_path, opts \\ []) do
    do_extract(&Native.extract/2, file_path, opts)
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

  @doc """
  Extracts text and metadata from binary data.

  ## Options

  Accepts a keyword list of options. See module documentation for full details.

  ## Examples

      # Extract from PDF bytes
      {:ok, pdf_data} = File.read("document.pdf")
      ExtractousEx.extract_from_bytes(pdf_data)
      {:ok, %{content: "Document text...", metadata: %{}}}

      # With options
      ExtractousEx.extract_from_bytes(data,
        xml: true,
        max_length: 100_000
      )
      {:ok, %{content: "<xml>...</xml>", metadata: %{}}}

  ## Returns

  Returns `{:ok, result}` on success where `result` is a map with:
    * `:content` - The extracted text content
    * `:metadata` - Document metadata as a map

  Returns `{:error, reason}` on failure.
  """
  @spec extract_from_bytes(binary(), keyword()) ::
          {:ok, %{content: String.t(), metadata: map()}} | {:error, String.t()}
  def extract_from_bytes(bytes, opts \\ []) do
    unless is_binary(bytes) do
      raise ArgumentError, "bytes must be a binary"
    end

    do_extract(&Native.extract_bytes/2, bytes, opts)
  end

  @doc """
  Extracts text from bytes, raising on error.

  Same as `extract_from_bytes/2` but raises an exception on failure.

  ## Examples

      {:ok, data} = File.read("document.pdf")
      ExtractousEx.extract_from_bytes!(data)
      %{content: "Document text...", metadata: %{}}

  """
  @spec extract_from_bytes!(binary(), keyword()) :: %{content: String.t(), metadata: map()}
  def extract_from_bytes!(bytes, opts \\ []) do
    case extract_from_bytes(bytes, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise "Failed to extract from bytes: #{inspect(reason)}"
    end
  end

  @doc """
  Extracts text and metadata from a URL.

  ## Options

  Accepts a keyword list of options. See module documentation for full details.

  ## Examples

      # Extract from a URL
      ExtractousEx.extract_from_url("https://example.com/document.pdf")
      {:ok, %{content: "Document text...", metadata: %{}}}

      # With options
      ExtractousEx.extract_from_url("https://example.com/doc.html",
        xml: true,
        office: [include_headers_and_footers: true]
      )
      {:ok, %{content: "<html>...</html>", metadata: %{}}}

  ## Returns

  Returns `{:ok, result}` on success where `result` is a map with:
    * `:content` - The extracted text content
    * `:metadata` - Document metadata as a map

  Returns `{:error, reason}` on failure.
  """
  @spec extract_from_url(String.t(), keyword()) ::
          {:ok, %{content: String.t(), metadata: map()}} | {:error, String.t()}
  def extract_from_url(url, opts \\ []) do
    unless is_binary(url) do
      raise ArgumentError, "url must be a string"
    end

    do_extract(&Native.extract_url/2, url, opts)
  end

  @doc """
  Extracts text from a URL, raising on error.

  Same as `extract_from_url/2` but raises an exception on failure.

  ## Examples

      ExtractousEx.extract_from_url!("https://example.com/document.pdf")
      %{content: "Document text...", metadata: %{}}

  """
  @spec extract_from_url!(String.t(), keyword()) :: %{content: String.t(), metadata: map()}
  def extract_from_url!(url, opts \\ []) do
    case extract_from_url(url, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise "Failed to extract from URL #{url}: #{inspect(reason)}"
    end
  end

  # Private helper functions

  defp do_extract(native_fun, input, opts) when is_list(opts) do
    unless Keyword.keyword?(opts) do
      raise ArgumentError, "Options must be a keyword list, got: #{inspect(opts)}"
    end

    # Always convert to JSON
    config_json = opts_to_json(opts)
    call_native_function(native_fun, [input, config_json])
  end

  defp do_extract(_native_fun, _input, opts) do
    raise ArgumentError, "Options must be a keyword list, got: #{inspect(opts)}"
  end

  defp opts_to_json(opts) when is_list(opts) do
    # Convert keyword list to a map structure for JSON serialization
    config_map = build_config_map(opts)

    if map_size(config_map) > 0 do
      case Jason.encode(config_map) do
        {:ok, json} -> json
        {:error, error} -> raise ArgumentError, "Failed to encode options to JSON: #{inspect(error)}"
      end
    else
      nil
    end
  end

  defp build_config_map(opts) do
    base_config = %{}

    # Add top-level options
    base_config =
      base_config
      |> maybe_add_option(:xml, Keyword.get(opts, :xml))
      |> maybe_add_option(:max_length, Keyword.get(opts, :max_length))
      |> maybe_add_option(:encoding, Keyword.get(opts, :encoding))

    # Add PDF options if present
    base_config =
      case Keyword.get(opts, :pdf) do
        nil -> base_config
        pdf_opts when is_list(pdf_opts) ->
          pdf_map = keyword_list_to_map(pdf_opts)
          Map.put(base_config, :pdf, pdf_map)
        _ -> raise ArgumentError, "pdf options must be a keyword list"
      end

    # Add Office options if present
    base_config =
      case Keyword.get(opts, :office) do
        nil -> base_config
        office_opts when is_list(office_opts) ->
          office_map = keyword_list_to_map(office_opts)
          Map.put(base_config, :office, office_map)
        _ -> raise ArgumentError, "office options must be a keyword list"
      end

    # Add OCR options if present
    base_config =
      case Keyword.get(opts, :ocr) do
        nil -> base_config
        ocr_opts when is_list(ocr_opts) ->
          ocr_map = keyword_list_to_map(ocr_opts)
          Map.put(base_config, :ocr, ocr_map)
        _ -> raise ArgumentError, "ocr options must be a keyword list"
      end

    base_config
  end

  defp maybe_add_option(map, _key, nil), do: map
  defp maybe_add_option(_map, :max_length, value) when not is_integer(value) do
    raise ArgumentError, "max_length must be an integer"
  end
  defp maybe_add_option(_map, :encoding, value) when not is_binary(value) do
    raise ArgumentError, "encoding must be a string"
  end
  defp maybe_add_option(map, key, value), do: Map.put(map, key, value)

  defp keyword_list_to_map(kw_list) when is_list(kw_list) do
    unless Keyword.keyword?(kw_list) do
      raise ArgumentError, "Nested options must be keyword lists"
    end

    Enum.into(kw_list, %{})
  end

  defp call_native_function(fun, args) do
    try do
      case apply(fun, args) do
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
end