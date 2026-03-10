use super::*;

pub(super) fn username_validation_accepts_expected_slug() {
    assert!(validate_username("layan-team").is_ok());
}

pub(super) fn username_validation_rejects_reserved() {
    assert!(validate_username("admin").is_err());
}

pub(super) fn password_min_length_enforced() {
    assert!(validate_password("1234567").is_err());
    assert!(validate_password("12345678").is_ok());
}

pub(super) fn token_hash_is_deterministic() {
    assert_eq!(hash_token("abc"), hash_token("abc"));
}

pub(super) fn otp_is_six_digits() {
    let otp = generate_otp_code();
    assert_eq!(otp.len(), 6);
    assert!(otp.chars().all(|char| char.is_ascii_digit()));
}

pub(super) fn user_agent_family_parse_works() {
    assert_eq!(
        parse_user_agent_family("Mozilla/5.0 Chrome/130.0"),
        Some("chrome".to_string())
    );
    assert_eq!(
        parse_user_agent_family("Mozilla/5.0 Firefox/128.0"),
        Some("firefox".to_string())
    );
}
