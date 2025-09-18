use rustler::NifResult;
use extractous::Extractor;

#[rustler::nif(schedule = "DirtyCpu")]
fn extract(file_path: String, as_xml: bool) -> NifResult<(String, String)> {
    let extractor = Extractor::new()
        .set_xml_output(as_xml);

    match extractor.extract_file_to_string(&file_path) {
        Ok((content, metadata)) => Ok((content, format!("{:?}", metadata))),
        Err(e) => Err(rustler::Error::Term(Box::new(format!("Extraction failed: {}", e)))),
    }
}

rustler::init!("Elixir.ExtractousEx.Native");
