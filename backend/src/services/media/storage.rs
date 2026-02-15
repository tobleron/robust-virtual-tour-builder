// @efficiency: infra-adapter
use std::fs;
use std::io;
use std::path::PathBuf;

pub struct StorageManager;

impl StorageManager {
    pub fn get_storage_root() -> PathBuf {
        // Use relative path "data/storage" which will resolve relative to the CWD (backend root)
        PathBuf::from("data/storage")
    }

    pub fn get_user_path(user_id: &str) -> io::Result<PathBuf> {
        let safe_user = crate::api::utils::sanitize_id(user_id)
            .map_err(|e| io::Error::new(io::ErrorKind::InvalidInput, e))?;
        Ok(Self::get_storage_root().join(safe_user))
    }

    pub fn get_user_project_path(user_id: &str, project_id: &str) -> io::Result<PathBuf> {
        let user_path = Self::get_user_path(user_id)?;
        let safe_project = crate::api::utils::sanitize_id(project_id)
            .map_err(|e| io::Error::new(io::ErrorKind::InvalidInput, e))?;
        Ok(user_path.join(safe_project))
    }

    pub fn ensure_project_dir(user_id: &str, project_id: &str) -> io::Result<PathBuf> {
        let path = Self::get_user_project_path(user_id, project_id)?;
        if !path.exists() {
            fs::create_dir_all(&path)?;
        }
        Ok(path)
    }

    pub fn init() -> io::Result<()> {
        let root = Self::get_storage_root();
        if !root.exists() {
            fs::create_dir_all(&root)?;
        }
        Ok(())
    }
}
