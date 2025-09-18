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
    assert String.contains?(result.content, "<html") or String.contains?(result.content, "<body") or String.contains?(result.content, "<")
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

end
