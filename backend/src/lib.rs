pub mod api;
pub mod models;
pub mod services;
pub mod middleware;
pub mod pathfinder;
pub mod metrics;

#[cfg(test)]
mod tests {
    #[test]
    fn test_modules_exist() {
        assert!(true);
    }
}
