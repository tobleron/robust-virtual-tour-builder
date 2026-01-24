pub mod api;
pub mod metrics;
pub mod middleware;
pub mod models;
pub mod pathfinder;
pub mod services;

#[cfg(test)]
mod tests {
    #[test]
    fn test_modules_exist() {
        assert!(true);
    }
}
