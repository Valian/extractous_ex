defmodule ExtractousExTest do
  use ExUnit.Case
  doctest ExtractousEx

  test "extracts text content from PDF" do
    pdf_path = Path.join([__DIR__, "fixtures", "pdf-test.pdf"])
    assert File.exists?(pdf_path)

    {:ok, result} = ExtractousEx.extract_from_file(pdf_path)

    assert is_binary(result.content)
    assert String.length(result.content) > 0
    assert is_map(result.metadata)
  end

  test "extracts text content from plain text file" do
    txt_path = Path.join([__DIR__, "fixtures", "test-document.txt"])
    assert File.exists?(txt_path)

    {:ok, result} = ExtractousEx.extract_from_file(txt_path)

    assert is_binary(result.content)
    assert String.contains?(result.content, "This is a plain text document")
    assert String.contains?(result.content, "Special characters: áéíóú")
    assert is_map(result.metadata)
  end

  test "extracts text content from HTML file" do
    html_path = Path.join([__DIR__, "fixtures", "test-document.html"])
    assert File.exists?(html_path)

    {:ok, result} = ExtractousEx.extract_from_file(html_path)

    assert is_binary(result.content)
    assert String.contains?(result.content, "HTML Document for Testing")
    assert String.contains?(result.content, "Special characters: áéíóú")
    # Should extract text content, not HTML tags
    refute String.contains?(result.content, "<html>")
    refute String.contains?(result.content, "<body>")
    assert is_map(result.metadata)
  end

  test "extracts text content from Markdown file" do
    md_path = Path.join([__DIR__, "fixtures", "test-document.md"])
    assert File.exists?(md_path)

    {:ok, result} = ExtractousEx.extract_from_file(md_path)

    assert is_binary(result.content)
    assert String.contains?(result.content, "Markdown Test Document")
    assert String.contains?(result.content, "Testing special characters: áéíóú")
    assert String.contains?(result.content, "ExtractousEx")
    assert is_map(result.metadata)
  end

  test "extracts text content from CSV file" do
    csv_path = Path.join([__DIR__, "fixtures", "test-document.csv"])
    assert File.exists?(csv_path)

    {:ok, result} = ExtractousEx.extract_from_file(csv_path)

    assert is_binary(result.content)
    assert String.contains?(result.content, "Name,Age,City")
    assert String.contains?(result.content, "John Doe")
    assert String.contains?(result.content, "Carlos González")
    assert is_map(result.metadata)
  end

  test "extracts text content from JSON file" do
    json_path = Path.join([__DIR__, "fixtures", "test-document.json"])
    assert File.exists?(json_path)

    {:ok, result} = ExtractousEx.extract_from_file(json_path)

    assert is_binary(result.content)
    assert String.contains?(result.content, "JSON Test Document")
    assert String.contains?(result.content, "Special characters: áéíóú")
    assert String.contains?(result.content, "Test Author")
    assert is_map(result.metadata)
  end

  test "extracts text content as plain text (xml: false)" do
    html_path = Path.join([__DIR__, "fixtures", "test-document.html"])
    assert File.exists?(html_path)

    {:ok, result} = ExtractousEx.extract_from_file(html_path, xml: false)

    assert is_binary(result.content)
    assert String.contains?(result.content, "HTML Document for Testing")
    # Should extract text content, not HTML tags
    refute String.contains?(result.content, "<html>")
    refute String.contains?(result.content, "<body>")
    assert is_map(result.metadata)
  end

  test "extracts text content as XML (xml: true)" do
    html_path = Path.join([__DIR__, "fixtures", "test-document.html"])
    assert File.exists?(html_path)

    {:ok, result} = ExtractousEx.extract_from_file(html_path, xml: true)

    assert is_binary(result.content)
    assert String.contains?(result.content, "HTML Document for Testing")
    # Should include XML/HTML structure when xml=true
    assert String.contains?(result.content, "<html") or String.contains?(result.content, "<body") or
             String.contains?(result.content, "<")

    assert is_map(result.metadata)
  end

  test "XML extraction works with different file formats" do
    formats = [
      {"test-document.txt", "plain text document"},
      {"test-document.md", "Markdown Test Document"}
    ]

    for {filename, expected_content} <- formats do
      file_path = Path.join([__DIR__, "fixtures", filename])
      assert File.exists?(file_path)

      # Test both XML modes
      {:ok, result_text} = ExtractousEx.extract_from_file(file_path, xml: false)
      {:ok, result_xml} = ExtractousEx.extract_from_file(file_path, xml: true)

      assert is_binary(result_text.content)
      assert is_binary(result_xml.content)
      assert String.contains?(result_text.content, expected_content)
      assert String.contains?(result_xml.content, expected_content)
      assert is_map(result_text.metadata)
      assert is_map(result_xml.metadata)
    end
  end

  @tag :tmp_dir
  test "handles files with random bytes gracefully", %{tmp_dir: tmp_dir} do
    # Create a temporary file with random bytes
    tmp_path = Path.join(tmp_dir, "test_invalid.bin")

    # Write random bytes that won't be recognized as any valid format
    File.write!(tmp_path, :crypto.strong_rand_bytes(1024))

    # Files without extensions are treated as binary/octet-stream by Tika
    # They return successfully with empty content rather than an error
    assert {:ok, %{content: "", metadata: metadata}} = ExtractousEx.extract_from_file(tmp_path)
    assert metadata["Content-Type"] == ["application/octet-stream"]
  end

  @tag :tmp_dir
  test "handles invalid PDF file with random bytes", %{tmp_dir: tmp_dir} do
    # Create a temporary file with random bytes but .pdf extension
    tmp_path = Path.join(tmp_dir, "test_invalid.pdf")

    # Write random bytes that are not a valid PDF
    File.write!(tmp_path, :crypto.strong_rand_bytes(1024))

    # Invalid PDF files should either return an error or empty content
    assert {:error, reason} = ExtractousEx.extract_from_file(tmp_path)
    assert reason =~ "Illegal IOException from org.apache.tika.parser.pdf.PDFParser"
  end

  @tag :tmp_dir
  test "returns error when file does not exist", %{tmp_dir: tmp_dir} do
    non_existent_path = Path.join(tmp_dir, "non_existent.pdf")

    assert {:error, _reason} = ExtractousEx.extract_from_file(non_existent_path)
  end

  test "respects max_length option" do
    txt_path = Path.join([__DIR__, "fixtures", "test-document.txt"])
    assert File.exists?(txt_path)

    # Test with a very small max_length
    {:ok, result} = ExtractousEx.extract_from_file(txt_path, max_length: 10)

    assert is_binary(result.content)
    # Content should be truncated
    assert String.length(result.content) <= 10
    assert is_map(result.metadata)
  end

  test "accepts encoding option" do
    txt_path = Path.join([__DIR__, "fixtures", "test-document.txt"])
    assert File.exists?(txt_path)

    # Test with UTF-8 encoding (default)
    {:ok, result_utf8} = ExtractousEx.extract_from_file(txt_path, encoding: "UTF-8")
    assert is_binary(result_utf8.content)
    assert is_map(result_utf8.metadata)

    # Test with US-ASCII encoding
    {:ok, result_ascii} = ExtractousEx.extract_from_file(txt_path, encoding: "US-ASCII")
    assert is_binary(result_ascii.content)
    assert is_map(result_ascii.metadata)

    # Test with UTF-16BE encoding
    {:ok, result_utf16} = ExtractousEx.extract_from_file(txt_path, encoding: "UTF-16BE")
    assert is_binary(result_utf16.content)
    assert is_map(result_utf16.metadata)
  end

  test "returns error for invalid encoding" do
    txt_path = Path.join([__DIR__, "fixtures", "test-document.txt"])
    assert File.exists?(txt_path)

    {:error, reason} = ExtractousEx.extract_from_file(txt_path, encoding: "INVALID-ENCODING")
    assert reason =~ "Unsupported encoding"
  end

  test "raises error when max_length is not an integer" do
    txt_path = Path.join([__DIR__, "fixtures", "test-document.txt"])

    assert_raise ArgumentError, "max_length must be an integer", fn ->
      ExtractousEx.extract_from_file(txt_path, max_length: "100")
    end
  end

  test "raises error when encoding is not a string" do
    txt_path = Path.join([__DIR__, "fixtures", "test-document.txt"])

    assert_raise ArgumentError, "encoding must be a string", fn ->
      ExtractousEx.extract_from_file(txt_path, encoding: :utf8)
    end
  end

  describe "extract_from_bytes/2" do
    test "extracts text from PDF bytes" do
      pdf_path = Path.join([__DIR__, "fixtures", "pdf-test.pdf"])
      {:ok, pdf_bytes} = File.read(pdf_path)

      {:ok, result} = ExtractousEx.extract_from_bytes(pdf_bytes)

      assert is_binary(result.content)
      assert String.length(result.content) > 0
      assert is_map(result.metadata)
    end

    test "extracts text from plain text bytes" do
      txt_path = Path.join([__DIR__, "fixtures", "test-document.txt"])
      {:ok, txt_bytes} = File.read(txt_path)

      {:ok, result} = ExtractousEx.extract_from_bytes(txt_bytes)

      assert is_binary(result.content)
      assert String.contains?(result.content, "This is a plain text document")
      assert String.contains?(result.content, "Special characters: áéíóú")
      assert is_map(result.metadata)
    end

    test "respects options for bytes extraction" do
      txt_path = Path.join([__DIR__, "fixtures", "test-document.txt"])
      {:ok, txt_bytes} = File.read(txt_path)

      # Test with max_length
      {:ok, result} = ExtractousEx.extract_from_bytes(txt_bytes, max_length: 20)
      assert String.length(result.content) <= 20

      # Test with XML output
      {:ok, result_xml} = ExtractousEx.extract_from_bytes(txt_bytes, xml: true)
      assert is_binary(result_xml.content)
    end

    test "raises error when bytes is not binary" do
      assert_raise ArgumentError, "bytes must be a binary", fn ->
        ExtractousEx.extract_from_bytes(123, [])
      end
    end

    test "extract_from_bytes! raises on error" do
      # Create invalid PDF-like data that will fail extraction
      invalid_pdf = "%PDF-1.4\n" <> :crypto.strong_rand_bytes(100)

      assert_raise RuntimeError, ~r/Failed to extract from bytes/, fn ->
        ExtractousEx.extract_from_bytes!(invalid_pdf)
      end
    end
  end

  describe "extract_from_url/2" do
    test "extracts text from a URL" do
      # Using a small test file from GitHub raw content
      url = "https://raw.githubusercontent.com/elixir-lang/elixir/main/LICENSE"

      {:ok, result} = ExtractousEx.extract_from_url(url)

      assert is_binary(result.content)
      assert String.contains?(result.content, "Apache")
      assert is_map(result.metadata)
    end

    test "respects options for URL extraction" do
      url = "https://raw.githubusercontent.com/elixir-lang/elixir/main/LICENSE"

      # Test with max_length
      {:ok, result} = ExtractousEx.extract_from_url(url, max_length: 50)
      assert String.length(result.content) <= 50

      # Test with XML output
      {:ok, result_xml} = ExtractousEx.extract_from_url(url, xml: true)
      assert is_binary(result_xml.content)
    end

    test "returns error for invalid URL" do
      {:error, reason} = ExtractousEx.extract_from_url("http://invalid-url-that-does-not-exist-12345.com/document.pdf")
      assert is_binary(reason)
    end

    test "raises error when URL is not a string" do
      assert_raise ArgumentError, "url must be a string", fn ->
        ExtractousEx.extract_from_url(123, [])
      end
    end

    test "extract_from_url! raises on error" do
      assert_raise RuntimeError, ~r/Failed to extract from URL/, fn ->
        ExtractousEx.extract_from_url!("http://invalid-url-that-does-not-exist-12345.com/document.pdf")
      end
    end
  end
end
