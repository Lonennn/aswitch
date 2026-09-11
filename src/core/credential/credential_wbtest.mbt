///|
fn with_credential_env(body : () -> Unit raise Error) -> Unit raise Error {
  let original_disable = @sys.get_env_var("ASWITCH_DISABLE_KEYCHAIN")
  let original_openai = @sys.get_env_var("ASWITCH_OPENAI_API_KEY")
  defer {
    match original_disable {
      Some(value) => @sys.set_env_var("ASWITCH_DISABLE_KEYCHAIN", value)
      None => @sys.unset_env_var("ASWITCH_DISABLE_KEYCHAIN")
    }
    match original_openai {
      Some(value) => @sys.set_env_var("ASWITCH_OPENAI_API_KEY", value)
      None => @sys.unset_env_var("ASWITCH_OPENAI_API_KEY")
    }
  }
  @sys.set_env_var("ASWITCH_DISABLE_KEYCHAIN", "1")
  @sys.unset_env_var("ASWITCH_OPENAI_API_KEY")
  body()
}

///|
fn credential_test_provider(api_key : String?) -> @provider.Provider {
  @provider.Provider::{
    name: "OpenAI",
    api_key,
    openai_base_url: Some("https://api.openai.com/v1"),
    anthropic_base_url: None,
    models: [@provider.Model::new(name="gpt-4o")],
  }
}

///|
test "provider_api_key_env_var canonicalizes provider name" {
  assert_true(provider_api_key_env_var("OpenAI") == "ASWITCH_OPENAI_API_KEY")
  assert_true(
    provider_api_key_env_var("Moonshot AI") == "ASWITCH_MOONSHOT_AI_API_KEY",
  )
}

///|
test "keychain read result decodes resolved secret" {
  let result = decode_keychain_read_result([
    0, b's', b'k', b'-', b't', b'e', b's', b't',
  ])
  assert_true(result is Ok(Some("sk-test")))
}

///|
test "keychain read result maps absence statuses" {
  assert_true(decode_keychain_read_result([1]) is Ok(None))
  assert_true(decode_keychain_read_result([2]) is Err(Unavailable))
  assert_true(decode_keychain_read_result([3]) is Err(Locked))
  assert_true(decode_keychain_read_result([4]) is Err(Denied))
  assert_true(decode_keychain_read_result([5]) is Err(Corrupt))
  assert_true(decode_keychain_read_result([255]) is Err(Corrupt))
}

///|
test "keychain read result rejects malformed packets" {
  assert_true(decode_keychain_read_result([]) is Err(Corrupt))
  assert_true(decode_keychain_read_result([0]) is Err(Corrupt))
  assert_true(decode_keychain_read_result([0, 0xff]) is Err(Corrupt))
  assert_true(decode_keychain_read_result([99]) is Err(Corrupt))
}

///|
test "resolve_provider_credential prefers environment variable" {
  with_credential_env(fn() raise {
    @sys.set_env_var("ASWITCH_OPENAI_API_KEY", "sk-env")
    let provider = credential_test_provider(Some("sk-inline"))
    let resolved = resolve_provider_credential(provider).unwrap()
    assert_true(resolved.value == "sk-env")
    assert_true(
      resolved.source
      is CredentialSource::EnvironmentVariable("ASWITCH_OPENAI_API_KEY"),
    )
  })
}

///|
test "resolve_provider_credential falls back to legacy inline key" {
  with_credential_env(fn() raise {
    let provider = credential_test_provider(Some("sk-inline"))
    let resolved = resolve_provider_credential(provider).unwrap()
    assert_true(resolved.value == "sk-inline")
    assert_true(resolved.source is CredentialSource::LegacyInline)
  })
}

///|
test "resolve_provider_credential fails when no source resolves" {
  with_credential_env(fn() raise {
    let provider = credential_test_provider(None)
    let result = resolve_provider_credential(provider)
    assert_true(result is Err(_))
  })
}
