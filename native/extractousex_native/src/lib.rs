use rustler::{NifResult, Binary};
use extractous::{Extractor, CharSet, PdfOcrStrategy, PdfParserConfig, OfficeParserConfig, TesseractOcrConfig};
use serde::{Deserialize, Serialize};

// JSON configuration structures with general options at top level
#[derive(Serialize, Deserialize, Debug, Default)]
struct ExtractorConfig {
    // Top-level general options (using backwards-compatible names)
    #[serde(default)]
    max_length: Option<i32>,
    #[serde(default)]
    xml: Option<bool>,
    #[serde(default)]
    encoding: Option<String>,

    // Nested config groups
    #[serde(default)]
    pdf: PdfSettings,
    #[serde(default)]
    office: OfficeSettings,
    #[serde(default)]
    ocr: OcrSettings,
}

#[derive(Serialize, Deserialize, Debug, Default)]
struct PdfSettings {
    ocr_strategy: Option<String>,
    extract_annotation_text: Option<bool>,
    extract_inline_images: Option<bool>,
    extract_unique_inline_images_only: Option<bool>,
    extract_marked_content: Option<bool>,
}

#[derive(Serialize, Deserialize, Debug, Default)]
struct OfficeSettings {
    include_shape_based_content: Option<bool>,
    include_slide_notes: Option<bool>,
    include_slide_master_content: Option<bool>,
    concatenate_phonetic_runs: Option<bool>,
    include_headers_and_footers: Option<bool>,
    include_deleted_content: Option<bool>,
    include_move_from_content: Option<bool>,
    include_missing_rows: Option<bool>,
    extract_macros: Option<bool>,
    extract_all_alternatives_from_msg: Option<bool>,
}

#[derive(Serialize, Deserialize, Debug, Default)]
struct OcrSettings {
    language: Option<String>,
    timeout_seconds: Option<i32>,
    density: Option<i32>,
    depth: Option<i32>,
    apply_rotation: Option<bool>,
    enable_image_preprocessing: Option<bool>,
}

fn configure_extractor_from_json(config_json: Option<String>) -> NifResult<Extractor> {
    let config = if let Some(json_str) = config_json {
        serde_json::from_str::<ExtractorConfig>(&json_str)
            .map_err(|e| rustler::Error::Term(Box::new(format!("Invalid JSON configuration: {}", e))))?
    } else {
        ExtractorConfig::default()
    };

    let mut extractor = Extractor::new();

    // Apply top-level general settings
    if let Some(max_length) = config.max_length {
        extractor = extractor.set_extract_string_max_length(max_length);
    }

    if let Some(xml) = config.xml {
        extractor = extractor.set_xml_output(xml);
    }

    if let Some(encoding) = config.encoding {
        let charset = match encoding.to_lowercase().as_str() {
            "utf8" | "utf-8" | "utf_8" => CharSet::UTF_8,
            "utf16be" | "utf-16be" | "utf_16be" => CharSet::UTF_16BE,
            "usascii" | "us-ascii" | "us_ascii" => CharSet::US_ASCII,
            _ => return Err(rustler::Error::Term(Box::new(format!(
                "Unsupported encoding: {}. Supported encodings: UTF-8, UTF-16BE, US-ASCII",
                encoding
            )))),
        };
        extractor = extractor.set_encoding(charset);
    }

    // Configure PDF parser
    let mut pdf_config = PdfParserConfig::new();

    if let Some(ocr_strategy) = config.pdf.ocr_strategy {
        let strategy = match ocr_strategy.to_uppercase().as_str() {
            "NO_OCR" => PdfOcrStrategy::NO_OCR,
            "AUTO" => PdfOcrStrategy::AUTO,
            "OCR_ONLY" => PdfOcrStrategy::OCR_ONLY,
            "OCR_AND_TEXT_EXTRACTION" => PdfOcrStrategy::OCR_AND_TEXT_EXTRACTION,
            _ => PdfOcrStrategy::AUTO,
        };
        pdf_config = pdf_config.set_ocr_strategy(strategy);
    }

    if let Some(extract_annotation_text) = config.pdf.extract_annotation_text {
        pdf_config = pdf_config.set_extract_annotation_text(extract_annotation_text);
    }

    if let Some(extract_inline_images) = config.pdf.extract_inline_images {
        pdf_config = pdf_config.set_extract_inline_images(extract_inline_images);
    }

    if let Some(extract_unique_inline_images_only) = config.pdf.extract_unique_inline_images_only {
        pdf_config = pdf_config.set_extract_unique_inline_images_only(extract_unique_inline_images_only);
    }

    if let Some(extract_marked_content) = config.pdf.extract_marked_content {
        pdf_config = pdf_config.set_extract_marked_content(extract_marked_content);
    }

    extractor = extractor.set_pdf_config(pdf_config);

    // Configure Office parser
    let mut office_config = OfficeParserConfig::new();

    if let Some(include_shape_based_content) = config.office.include_shape_based_content {
        office_config = office_config.set_include_shape_based_content(include_shape_based_content);
    }

    if let Some(include_slide_notes) = config.office.include_slide_notes {
        office_config = office_config.set_include_slide_notes(include_slide_notes);
    }

    if let Some(include_slide_master_content) = config.office.include_slide_master_content {
        office_config = office_config.set_include_slide_master_content(include_slide_master_content);
    }

    if let Some(concatenate_phonetic_runs) = config.office.concatenate_phonetic_runs {
        office_config = office_config.set_concatenate_phonetic_runs(concatenate_phonetic_runs);
    }

    if let Some(include_headers_and_footers) = config.office.include_headers_and_footers {
        office_config = office_config.set_include_headers_and_footers(include_headers_and_footers);
    }

    if let Some(include_deleted_content) = config.office.include_deleted_content {
        office_config = office_config.set_include_deleted_content(include_deleted_content);
    }

    if let Some(include_move_from_content) = config.office.include_move_from_content {
        office_config = office_config.set_include_move_from_content(include_move_from_content);
    }

    if let Some(include_missing_rows) = config.office.include_missing_rows {
        office_config = office_config.set_include_missing_rows(include_missing_rows);
    }

    if let Some(extract_macros) = config.office.extract_macros {
        office_config = office_config.set_extract_macros(extract_macros);
    }

    if let Some(extract_all_alternatives_from_msg) = config.office.extract_all_alternatives_from_msg {
        office_config = office_config.set_extract_all_alternatives_from_msg(extract_all_alternatives_from_msg);
    }

    extractor = extractor.set_office_config(office_config);

    // Configure Tesseract OCR
    let mut ocr_config = TesseractOcrConfig::new();

    if let Some(language) = config.ocr.language {
        ocr_config = ocr_config.set_language(&language);
    }

    if let Some(timeout_seconds) = config.ocr.timeout_seconds {
        ocr_config = ocr_config.set_timeout_seconds(timeout_seconds);
    }

    if let Some(density) = config.ocr.density {
        ocr_config = ocr_config.set_density(density);
    }

    if let Some(depth) = config.ocr.depth {
        ocr_config = ocr_config.set_depth(depth);
    }

    if let Some(apply_rotation) = config.ocr.apply_rotation {
        ocr_config = ocr_config.set_apply_rotation(apply_rotation);
    }

    if let Some(enable_image_preprocessing) = config.ocr.enable_image_preprocessing {
        ocr_config = ocr_config.set_enable_image_preprocessing(enable_image_preprocessing);
    }

    extractor = extractor.set_ocr_config(ocr_config);

    Ok(extractor)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn extract(file_path: String, config_json: Option<String>) -> NifResult<(String, String)> {
    let extractor = configure_extractor_from_json(config_json)?;

    match extractor.extract_file_to_string(&file_path) {
        Ok((content, metadata)) => Ok((content, format!("{:?}", metadata))),
        Err(e) => Err(rustler::Error::Term(Box::new(format!("Extraction failed: {}", e)))),
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn extract_bytes(buffer: Binary, config_json: Option<String>) -> NifResult<(String, String)> {
    let extractor = configure_extractor_from_json(config_json)?;
    let bytes = buffer.as_slice();

    match extractor.extract_bytes_to_string(bytes) {
        Ok((content, metadata)) => Ok((content, format!("{:?}", metadata))),
        Err(e) => Err(rustler::Error::Term(Box::new(format!("Extraction from bytes failed: {}", e)))),
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn extract_url(url: String, config_json: Option<String>) -> NifResult<(String, String)> {
    let extractor = configure_extractor_from_json(config_json)?;

    match extractor.extract_url_to_string(&url) {
        Ok((content, metadata)) => Ok((content, format!("{:?}", metadata))),
        Err(e) => Err(rustler::Error::Term(Box::new(format!("Extraction from URL failed: {}", e)))),
    }
}

rustler::init!("Elixir.ExtractousEx.Native");