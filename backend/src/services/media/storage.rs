use std::fs;
use std::io;
use std::path::PathBuf;

pub struct StorageManager;

impl StorageManager {
    pub fn get_storage_root() -> PathBuf {
        // Use relative path "data/storage" which will resolve relative to the CWD (backend root)
        PathBuf::from("data/storage")
    }

    pub fn get_user_path(user_id: &str) -> PathBuf {
        Self::get_storage_root().join(user_id)
    }

    pub fn get_user_project_path(user_id: &str, project_id: &str) -> PathBuf {
        Self::get_user_path(user_id).join(project_id)
    }

    pub fn ensure_project_dir(user_id: &str, project_id: &str) -> io::Result<PathBuf> {
        let path = Self::get_user_project_path(user_id, project_id);
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
