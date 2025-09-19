use rustler::NifResult;
use extractous::{Extractor, CharSet};

#[rustler::nif(schedule = "DirtyCpu")]
fn extract(file_path: String, as_xml: bool, max_length: Option<i32>, encoding: Option<String>) -> NifResult<(String, String)> {
    let mut extractor = Extractor::new()
        .set_xml_output(as_xml);

    if let Some(max_len) = max_length {
        extractor = extractor.set_extract_string_max_length(max_len);
    }

    if let Some(enc) = encoding {
        let charset = match enc.to_lowercase().as_str() {
            "utf8" | "utf-8" => CharSet::UTF_8,
            "utf16be" | "utf-16be" => CharSet::UTF_16BE,
            "usascii" | "us-ascii" => CharSet::US_ASCII,
            _ => return Err(rustler::Error::Term(Box::new(format!("Unsupported encoding: {}. Supported encodings: UTF-8, UTF-16BE, US-ASCII", enc)))),
        };
        extractor = extractor.set_encoding(charset);
    }

    match extractor.extract_file_to_string(&file_path) {
        Ok((content, metadata)) => Ok((content, format!("{:?}", metadata))),
        Err(e) => Err(rustler::Error::Term(Box::new(format!("Extraction failed: {}", e)))),
    }
}

rustler::init!("Elixir.ExtractousEx.Native");
