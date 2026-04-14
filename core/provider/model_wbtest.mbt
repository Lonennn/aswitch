///|
/// Whitebox tests for Model struct and related functions

///|
test "Model::new - creates model with default modalities" {
  let model = Model::new(name="test-model")
  assert_eq(model.name, "test-model")
  assert_eq(model.context_limit, None)
  assert_eq(model.output_limit, None)
  assert_true(model.input_modality == [Modality::Text])
  assert_true(model.output_modality == [Modality::Text])
}

///|
test "Model::new - creates model with custom limits" {
  let model = Model::new(name="gpt-4", context_limit=8192, output_limit=4096)
  assert_eq(model.name, "gpt-4")
  assert_eq(model.context_limit, Some(8192))
  assert_eq(model.output_limit, Some(4096))
  assert_true(model.input_modality == [Modality::Text])
  assert_true(model.output_modality == [Modality::Text])
}

///|
test "FromJson for Model - minimal JSON with only name" {
  let json : Json = { "name": "minimal-model" }
  let model : Model = @json.from_json(json)
  assert_eq(model.name, "minimal-model")
  assert_eq(model.context_limit, None)
  assert_eq(model.output_limit, None)
  assert_true(model.input_modality == [Modality::Text])
  assert_true(model.output_modality == [Modality::Text])
}

///|
test "FromJson for Model - full JSON with all fields" {
  let json : Json = {
    "name": "vision-model",
    "context_limit": 128000,
    "output_limit": 8192,
    "input_modality": ["Text", "Vision"],
    "output_modality": ["Text"],
  }
  let model : Model = @json.from_json(json)
  assert_eq(model.name, "vision-model")
  assert_eq(model.context_limit, Some(128000))
  assert_eq(model.output_limit, Some(8192))
  assert_true(model.input_modality == [Modality::Text, Modality::Vision])
  assert_true(model.output_modality == [Modality::Text])
}

///|
test "FromJson for Model - null optional fields are handled correctly" {
  let json : Json = {
    "name": "null-fields-model",
    "context_limit": null,
    "output_limit": null,
    "input_modality": null,
    "output_modality": null,
  }
  let model : Model = @json.from_json(json)
  assert_eq(model.context_limit, None)
  assert_eq(model.output_limit, None)
  assert_true(model.input_modality == [Modality::Text])
  assert_true(model.output_modality == [Modality::Text])
}

///|
test "FromJson for Model - error when name is missing" {
  let json : Json = { "context_limit": 1000 }
  let result : Result[Model, Error] = try? @json.from_json(json)
  match result {
    Err(_) =>
      inspect(
        "missing name error raised correctly",
        content="missing name error raised correctly",
      )
    Ok(_) => fail("should have raised error for missing name")
  }
}

///|
test "FromJson for Model - error when name is not a string" {
  let json : Json = { "name": 123 }
  let result : Result[Model, Error] = try? @json.from_json(json)
  match result {
    Err(_) =>
      inspect(
        "invalid name type error raised correctly",
        content="invalid name type error raised correctly",
      )
    Ok(_) => fail("should have raised error for non-string name")
  }
}

///|
test "FromJson for Model - error when context_limit is not a number" {
  let json : Json = { "name": "test", "context_limit": "not-a-number" }
  let result : Result[Model, Error] = try? @json.from_json(json)
  match result {
    Err(_) =>
      inspect(
        "invalid context_limit type error raised correctly",
        content="invalid context_limit type error raised correctly",
      )
    Ok(_) => fail("should have raised error for non-number context_limit")
  }
}

///|
test "FromJson for Model - error when output_limit is not a number" {
  let json : Json = { "name": "test", "output_limit": ["wrong", "type"] }
  let result : Result[Model, Error] = try? @json.from_json(json)
  match result {
    Err(_) =>
      inspect(
        "invalid output_limit type error raised correctly",
        content="invalid output_limit type error raised correctly",
      )
    Ok(_) => fail("should have raised error for non-number output_limit")
  }
}

///|
test "FromJson for Model - error when modality is invalid" {
  let json : Json = {
    "name": "test",
    "input_modality": ["text", "invalid-modality"],
  }
  let result : Result[Model, Error] = try? @json.from_json(json)
  match result {
    Err(_) =>
      inspect(
        "invalid modality error raised correctly",
        content="invalid modality error raised correctly",
      )
    Ok(_) => fail("should have raised error for invalid modality")
  }
}
