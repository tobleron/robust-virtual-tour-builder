use super::*;
use actix_web::http::header::{AUTHORIZATION, COOKIE};
use actix_web::test::TestRequest;

#[test]
fn extract_auth_token_prefers_authorization_header() {
    let req = TestRequest::default()
        .insert_header((AUTHORIZATION, "Bearer header-token"))
        .insert_header((COOKIE, "auth_token=cookie-token"))
        .to_http_request();
    assert_eq!(extract_auth_token(&req), Some("header-token".to_string()));
}

#[test]
fn extract_auth_token_falls_back_to_cookie() {
    let req = TestRequest::default()
        .insert_header((COOKIE, "auth_token=cookie-token"))
        .to_http_request();
    assert_eq!(extract_auth_token(&req), Some("cookie-token".to_string()));
}

#[test]
fn parse_motion_profile_decodes_camel_case_payload() {
    let payload = br#"{"skipAutoForward":true,"startAtWaypoint":false,"includeIntroPan":true}"#;
    let parsed = parse_motion_profile(payload).expect("motion profile should parse");
    assert!(parsed.skip_auto_forward);
    assert!(!parsed.start_at_waypoint);
    assert!(parsed.include_intro_pan);
}

#[test]
fn parse_motion_profile_rejects_invalid_payload() {
    let payload = br#"{"skipAutoForward":"yes","startAtWaypoint":true}"#;
    assert!(parse_motion_profile(payload).is_none());
}

#[test]
fn parse_motion_manifest_decodes_valid_payload() {
    let payload = br#"{
        "version": "motion-spec-v1",
        "fps": 60,
        "canvasWidth": 1920,
        "canvasHeight": 1080,
        "includeIntroPan": false,
        "shots": [
            {
                "sceneId": "s1",
                "arrivalPose": {"yaw": 0.0, "pitch": 0.0, "hfov": 90.0},
                "animationSegments": [
                    {
                        "startYaw": 0.0, "endYaw": 10.0,
                        "startPitch": 0.0, "endPitch": 0.0,
                        "startHfov": 90.0, "endHfov": 90.0,
                        "easing": "linear",
                        "durationMs": 1000
                    }
                ],
                "transitionOut": {"type": "crossfade", "durationMs": 500}
            }
        ]
    }"#;
    let parsed = parse_motion_manifest(payload).expect("motion manifest should parse");
    assert_eq!(parsed.version, "motion-spec-v1");
    assert_eq!(parsed.shots.len(), 1);
    assert_eq!(parsed.shots[0].scene_id, "s1");
}

#[test]
fn validate_motion_manifest_rejects_invalid_version() {
    let manifest = crate::api::media::video_logic_support::MotionManifestV1 {
        version: "v2".into(),
        fps: 60,
        canvas_width: 1920,
        canvas_height: 1080,
        include_intro_pan: false,
        shots: vec![],
    };
    assert!(validate_motion_manifest(&manifest).is_err());
}

#[test]
fn validate_motion_manifest_rejects_invalid_fps() {
    let manifest_zero = crate::api::media::video_logic_support::MotionManifestV1 {
        version: "motion-spec-v1".into(),
        fps: 0,
        canvas_width: 1920,
        canvas_height: 1080,
        include_intro_pan: false,
        shots: vec![],
    };
    assert!(validate_motion_manifest(&manifest_zero).is_err());

    let manifest_high = crate::api::media::video_logic_support::MotionManifestV1 {
        version: "motion-spec-v1".into(),
        fps: 144,
        canvas_width: 1920,
        canvas_height: 1080,
        include_intro_pan: false,
        shots: vec![],
    };
    assert!(validate_motion_manifest(&manifest_high).is_err());
}

#[test]
fn validate_motion_manifest_rejects_empty_shots() {
    let manifest = crate::api::media::video_logic_support::MotionManifestV1 {
        version: "motion-spec-v1".into(),
        fps: 30,
        canvas_width: 1920,
        canvas_height: 1080,
        include_intro_pan: false,
        shots: vec![],
    };
    assert!(validate_motion_manifest(&manifest).is_err());
}

#[test]
fn validate_motion_manifest_accepts_valid_manifest() {
    let manifest = crate::api::media::video_logic_support::MotionManifestV1 {
        version: "motion-spec-v1".into(),
        fps: 60,
        canvas_width: 1920,
        canvas_height: 1080,
        include_intro_pan: false,
        shots: vec![crate::api::media::video_logic_support::MotionShot {
            scene_id: "s1".into(),
            arrival_pose: crate::api::media::video_logic_support::ArrivalPose {
                yaw: 0.0,
                pitch: 0.0,
                hfov: 90.0,
            },
            animation_segments: vec![],
            transition_out: None,
        }],
    };
    assert!(validate_motion_manifest(&manifest).is_ok());
}
