defmodule ExtractousEx.Native do
  version = Mix.Project.config()[:version]

  use RustlerPrecompiled,
    otp_app: :extractous_ex,
    crate: "extractousex_native",
    base_url: "https://github.com/Valian/extractous_ex/releases/download/v#{version}",
    version: version,
    nif_versions: ["2.15"],
    targets: [
      "aarch64-apple-darwin",
      "x86_64-apple-darwin",
      "x86_64-unknown-linux-gnu",
      "aarch64-unknown-linux-gnu",
      "x86_64-pc-windows-gnu"
    ],
    mode: if(Mix.env() in [:dev, :test], do: :debug, else: :release),
    force_build: System.get_env("EXTRACTOUS_EX_BUILD") in ["1", "true"]

  # JSON-based configuration NIFs
  def extract(_file_path, _config_json), do: :erlang.nif_error(:nif_not_loaded)
  def extract_bytes(_buffer, _config_json), do: :erlang.nif_error(:nif_not_loaded)
  def extract_url(_url, _config_json), do: :erlang.nif_error(:nif_not_loaded)
end