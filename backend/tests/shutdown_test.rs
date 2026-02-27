// @efficiency: infra-adapter
#[tokio::test]
async fn test_graceful_shutdown() {
    use backend::services::shutdown::ShutdownManager;
    use std::time::Duration;

    let manager = ShutdownManager::new(Duration::from_secs(5));

    // Simulate active requests
    manager.register_request();
    manager.register_request();

    assert_eq!(manager.active_count(), 2);

    // Simulate completion
    manager.unregister_request();
    assert_eq!(manager.active_count(), 1);

    manager.unregister_request();
    assert_eq!(manager.active_count(), 0);

    // Should complete immediately
    let completed = manager.wait_for_completion().await;
    assert!(completed);
}

#[tokio::test]
async fn test_shutdown_timeout() {
    use backend::services::shutdown::ShutdownManager;
    use std::time::Duration;

    let manager = ShutdownManager::new(Duration::from_secs(1));

    // Simulate stuck request
    manager.register_request();

    // Should timeout
    let completed = manager.wait_for_completion().await;
    assert!(!completed);
}
