# ExtractousEx

<!-- MDOC -->

<div align="center">
  <br>

  <a href="https://hex.pm/packages/extractous_ex">
    <img alt="Hex Version" src="https://img.shields.io/hexpm/v/extractous_ex">
  </a>

  <a href="https://hexdocs.pm/extractous_ex">
    <img alt="Hex Docs" src="http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat">
  </a>

  <a href="https://github.com/Valian/extractous_ex/actions">
    <img alt="CI" src="https://github.com/Valian/extractous_ex/workflows/Release/badge.svg">
  </a>

  <a href="https://opensource.org/licenses/MIT">
    <img alt="MIT" src="https://img.shields.io/hexpm/l/extractous_ex">
  </a>

  <a href="https://hex.pm/packages/extractous_ex">
    <img alt="Downloads" src="https://img.shields.io/hexpm/dt/extractous_ex">
  </a>

  <p align="center">Fast and comprehensive document text extraction for Elixir.</p>
</div>

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

ExtractousEx provides three main extraction methods:

```elixir
# Extract from a file on disk
{:ok, result} = ExtractousEx.extract_from_file("document.pdf")

# Extract from binary data in memory
{:ok, data} = File.read("document.pdf")
{:ok, result} = ExtractousEx.extract_from_bytes(data)

# Extract from a URL
{:ok, result} = ExtractousEx.extract_from_url("https://example.com/document.pdf")

# Access extracted content and metadata
IO.puts(result.content)
# => "Document text content..."

IO.inspect(result.metadata)
# => %{"author" => "John Doe", "title" => "My Document", ...}
```

### Options

All extraction methods support the same options:

```elixir
# Extract with XML structure preserved
{:ok, result} = ExtractousEx.extract_from_file("document.html", xml: true)

# Limit extracted text length (default: 500,000 characters)
{:ok, result} = ExtractousEx.extract_from_bytes(data, max_length: 100_000)

# Specify encoding (UTF-8, UTF-16BE, US-ASCII)
{:ok, result} = ExtractousEx.extract_from_url(url, encoding: "UTF-16BE")

# Combine options
{:ok, result} = ExtractousEx.extract_from_file("doc.pdf",
  xml: true,
  max_length: 50_000,
  encoding: "UTF-8"
)
```

### Error Handling

```elixir
# Standard tuple return for all methods
case ExtractousEx.extract_from_file("nonexistent.pdf") do
  {:ok, result} ->
    IO.puts("Content: #{result.content}")
  {:error, reason} ->
    IO.puts("Failed to extract: #{reason}")
end

# Bang versions available for all methods (raise on error)
result = ExtractousEx.extract_from_file!("document.pdf")
result = ExtractousEx.extract_from_bytes!(data)
result = ExtractousEx.extract_from_url!(url)
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

## Foundation

The library is built on top of:

- [Extractous](https://github.com/yobix-ai/extractous) - a fast Rust library for document text extraction
- [Rustler](https://github.com/rusterlium/rustler) for seamless Elixir-Rust integration
- [rustler_precompiled](https://github.com/philss/rustler_precompiled) for cross-platform binary distribution

<!-- MDOC -->

