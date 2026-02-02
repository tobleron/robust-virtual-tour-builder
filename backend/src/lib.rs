pub mod api;
pub mod auth;
pub mod metrics;
pub mod middleware;
pub mod models;
pub mod pathfinder;
pub mod services;
pub mod startup;

#[cfg(test)]
mod tests {
    #[test]
    fn test_modules_exist() {
        assert!(true);
    }
}
