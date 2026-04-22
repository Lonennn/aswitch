///|
/// Model configuration with name and optional limits/modality settings
pub(all) struct Model {
  /// Model name
  name : String
  /// Optional context window limit (in tokens)
  context_limit : Int?
  /// Optional output limit (in tokens)
  output_limit : Int?
  /// Input modalities (default: [Text])
  input_modality : Array[Modality]
  /// Output modalities (default: [Text])
  output_modality : Array[Modality]
} derive(Debug, Eq, ToJson)

///|
/// Create a Model with default modality settings (Text for input and output)
pub fn Model::new(
  name~ : String,
  context_limit? : Int,
  output_limit? : Int,
) -> Model {
  Model::{
    name,
    context_limit,
    output_limit,
    input_modality: [Modality::Text],
    output_modality: [Modality::Text],
  }
}

///|
pub fn Model::deep_copy(self : Model) -> Model {
  Model::{
    name: self.name.to_string(),
    context_limit: self.context_limit,
    output_limit: self.output_limit,
    input_modality: self.input_modality.map(fn(modality) { modality }),
    output_modality: self.output_modality.map(fn(modality) { modality }),
  }
}

///|
impl FromJson for Model with from_json(json, path) {
  match json {
    Json::Object(map) => {

      // Required field
      let name = match map.get("name") {
        Some(Json::String(s)) => s
        Some(_) =>
          raise JsonDecodeError((path.add_key("name"), "Expected string"))
        None =>
          raise JsonDecodeError((path.add_key("name"), "Missing field name"))
      }
      // Optional Int? fields
      let context_limit : Int? = match map.get("context_limit") {
        Some(Json::Null) | None => None
        Some(Json::Number(n, ..)) => Some(n.to_int())
        Some(_) =>
          raise JsonDecodeError(
            (path.add_key("context_limit"), "Expected number"),
          )
      }
      let output_limit : Int? = match map.get("output_limit") {
        Some(Json::Null) | None => None
        Some(Json::Number(n, ..)) => Some(n.to_int())
        Some(_) =>
          raise JsonDecodeError(
            (path.add_key("output_limit"), "Expected number"),
          )
      }
      // Default to [Text] if missing
      let input_modality : Array[Modality] = match map.get("input_modality") {
        None | Some(Json::Null) => [Modality::Text]
        Some(arr) => @json.from_json(arr)
      }
      let output_modality : Array[Modality] = match map.get("output_modality") {
        None | Some(Json::Null) => [Modality::Text]
        Some(arr) => @json.from_json(arr)
      }
      Model::{
        name,
        context_limit,
        output_limit,
        input_modality,
        output_modality,
      }
    }
    _ => raise JsonDecodeError((path, "Expected object for Model"))
  }
}
