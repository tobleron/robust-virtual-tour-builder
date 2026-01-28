// @efficiency: infra-adapter
use super::upload_quota::*;

#[tokio::test]
async fn test_quota_allows_small_upload() {
    let config = QuotaConfig::default();
    let manager = UploadQuotaManager::new(config);

    let result = manager.can_upload("127.0.0.1", 1024 * 1024).await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_quota_rejects_oversized_upload() {
    let config = QuotaConfig {
        max_payload_size: 1024 * 1024, // 1MB
        ..Default::default()
    };
    let manager = UploadQuotaManager::new(config);

    let result = manager.can_upload("127.0.0.1", 2 * 1024 * 1024).await;
    assert!(result.is_err());
}

#[tokio::test]
async fn test_concurrent_limit_per_ip() {
    let config = QuotaConfig {
        max_concurrent_per_ip: 1,
        ..Default::default()
    };
    let manager = UploadQuotaManager::new(config);

    // First upload should succeed
    manager.register_upload("127.0.0.1", 1024).await;

    // Second concurrent upload should fail
    let result = manager.can_upload("127.0.0.1", 1024).await;
    assert!(result.is_err());

    // After unregister, should succeed again
    manager.unregister_upload("127.0.0.1", 1024).await;
    let result = manager.can_upload("127.0.0.1", 1024).await;
    assert!(result.is_ok());
}
