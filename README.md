# ExtractousEx

ExtractousEx is an Elixir library for extracting text and metadata from various document formats using the powerful [Extractous](https://github.com/yobix-ai/extractous) Rust library.

## Features

- **High Performance**: Built on Rust with precompiled binaries for fast extraction
- **Multiple Formats**: Supports PDF, Microsoft Office documents, HTML, plain text, CSV, JSON, Markdown, and many more
- **Metadata Extraction**: Extracts document metadata alongside text content
- **XML Output**: Optional structured XML output for preserving document formatting
- **Cross-Platform**: Precompiled binaries for macOS (arm64/x64), Linux (arm64/x64), and Windows (x64)
- **Elixir Native**: Idiomatic Elixir API with proper error handling

## Installation

Add `extractous_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:extractous_ex, "~> 0.1.0"}
  ]
end
```

## Usage

### Basic Text Extraction

```elixir
# Extract plain text from a document
{:ok, result} = ExtractousEx.extract_from_file("document.pdf")

# Access extracted content and metadata
content = result.content
metadata = result.metadata

IO.puts(content)
# => "Document text content..."

IO.inspect(metadata)
# => %{"author" => "John Doe", "title" => "My Document", ...}
```

### XML Output

For documents where structure matters, you can extract as XML:

```elixir
# Extract with XML structure preserved
{:ok, result} = ExtractousEx.extract_from_file("document.html", xml: true)

content = result.content
# => "<html><body><h1>Title</h1><p>Content...</p></body></html>"
```

### Error Handling

```elixir
case ExtractousEx.extract_from_file("nonexistent.pdf") do
  {:ok, result} ->
    IO.puts("Content: #{result.content}")
  {:error, reason} ->
    IO.puts("Failed to extract: #{reason}")
end

# Or use the bang version that raises on error
result = ExtractousEx.extract_from_file!("document.pdf")
```

## Supported Formats

ExtractousEx supports a wide variety of document formats including:

- **PDF**: Portable Document Format
- **Microsoft Office**: Word (.docx, .doc), Excel (.xlsx, .xls), PowerPoint (.pptx, .ppt)
- **OpenDocument**: Writer (.odt), Calc (.ods), Impress (.odp)
- **Web**: HTML, XML
- **Text**: Plain text (.txt), Markdown (.md), CSV
- **E-books**: EPUB
- **Images**: With OCR support (when available)
- **Archives**: ZIP, TAR (extracts contained documents)
- **Email**: EML, MSG formats

## Configuration

### Force Building from Source

If you need to build from source instead of using precompiled binaries:

```bash
export EXTRACTOUS_EX_BUILD=1
mix deps.compile extractous_ex
```

### Development Setup

For development or when precompiled binaries aren't available:

```elixir
# In config/config.exs
config :rustler_precompiled, :force_build, extractous_ex: true
```

## Performance

ExtractousEx leverages the Extractous Rust library, which provides:

- ~18x faster extraction compared to unstructured-io
- ~11x less memory consumption
- High-quality content extraction across formats

## Examples

### Extract from Multiple Formats

```elixir
files = ["report.pdf", "data.csv", "presentation.pptx", "webpage.html"]

Enum.each(files, fn file ->
  case ExtractousEx.extract_from_file(file) do
    {:ok, result} ->
      IO.puts("#{file}: #{String.slice(result.content, 0, 100)}...")
    {:error, reason} ->
      IO.puts("Failed to extract #{file}: #{reason}")
  end
end)
```

### Batch Processing

```elixir
files = Path.wildcard("documents/*.{pdf,docx,html}")

results = files
|> Task.async_stream(fn file ->
  {file, ExtractousEx.extract_from_file(file)}
end, max_concurrency: System.schedulers_online())
|> Enum.map(fn {:ok, result} -> result end)

for {file, {:ok, result}} <- results do
  IO.puts("#{file}: #{byte_size(result.content)} characters extracted")
end
```

## Building and Releasing

This project uses GitHub Actions to automatically build precompiled binaries for multiple platforms. When you push a version tag (e.g., `v0.1.0`), the workflow will:

1. Build binaries for macOS, Linux, and Windows
2. Create a GitHub release with the precompiled `.tar.gz` files
3. Users automatically get fast precompiled binaries instead of compiling Rust

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `mix test`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on the excellent [Extractous](https://github.com/yobix-ai/extractous) Rust library
- Uses [Rustler](https://github.com/rusterlium/rustler) for Elixir-Rust integration
- Precompiled binary distribution via [rustler_precompiled](https://github.com/philss/rustler_precompiled)

