# Markdown Test Document

This is a **Markdown document** for testing text extraction capabilities.

## Features

- Headers at different levels
- *Italic* and **bold** text
- Lists with various items
- Code blocks and `inline code`

### Code Example

```elixir
defmodule ExtractousEx do
  def extract_text(file_path) do
    ExtractousEx.Native.extract_file_to_string(file_path)
  end
end
```

### Special Characters

Testing special characters: áéíóú, ñ, €, @, #, $, %, &

> This is a blockquote to test how quotes are handled.

The extraction should preserve the textual content while handling Markdown formatting appropriately.

---

## Conclusion

This document tests various Markdown elements for extraction accuracy.