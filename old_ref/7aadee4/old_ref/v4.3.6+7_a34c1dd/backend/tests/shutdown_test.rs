#[tokio::test]
async fn test_graceful_shutdown() {
    use backend::services::shutdown::ShutdownManager;
    use std::time::Duration;

    let manager = ShutdownManager::new(Duration::from_secs(5));

    // Simulate active requests
    manager.register_request().await;
    manager.register_request().await;

    assert_eq!(manager.active_count().await, 2);

    // Simulate completion
    manager.unregister_request().await;
    assert_eq!(manager.active_count().await, 1);

    manager.unregister_request().await;
    assert_eq!(manager.active_count().await, 0);

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
    manager.register_request().await;

    // Should timeout
    let completed = manager.wait_for_completion().await;
    assert!(!completed);
}
