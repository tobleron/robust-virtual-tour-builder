/**
 * CacheSystem - IndexedDB caching layer for large binary files
 * 
 * This system provides persistent caching for:
 * - FFmpeg WebAssembly core files (~31 MB)
 * - Generated teaser videos
 * - Potentially other large assets
 * 
 * Benefits:
 * - Eliminates redundant downloads (saves bandwidth and time)
 * - Enables offline functionality
 * - Improves app startup performance
 * 
 * @module CacheSystem
 */

const DB_NAME = "RemaxVTBuilderCache";
const DB_VERSION = 1;
const STORE_NAME = "binaryAssets";

/**
 * IndexedDB wrapper for caching large binary files
 */
export class CacheSystem {
    static db = null;

    /**
     * Initialize the IndexedDB database
     * Creates the object store if it doesn't exist
     * 
     * @returns {Promise<IDBDatabase>} Initialized database connection
     * @throws {Error} If IndexedDB is not supported or initialization fails
     */
    static async init() {
        // Return existing connection if already initialized
        if (this.db) return this.db;

        // Check for IndexedDB support
        if (!window.indexedDB) {
            console.warn("[CacheSystem] IndexedDB not supported in this browser");
            return null;
        }

        return new Promise((resolve, reject) => {
            const request = indexedDB.open(DB_NAME, DB_VERSION);

            /**
             * Database upgrade handler - creates object stores
             * Only runs when DB is first created or version changes
             */
            request.onupgradeneeded = (event) => {
                const db = event.target.result;

                // Create object store if it doesn't exist
                if (!db.objectStoreNames.contains(STORE_NAME)) {
                    db.createObjectStore(STORE_NAME);
                    console.log("[CacheSystem] Created object store:", STORE_NAME);
                }
            };

            request.onsuccess = (event) => {
                this.db = event.target.result;
                console.log("[CacheSystem] Database initialized successfully");
                resolve(this.db);
            };

            request.onerror = (event) => {
                console.error("[CacheSystem] Database initialization failed:", event.target.error);
                reject(event.target.error);
            };
        });
    }

    /**
     * Store a binary file in the cache
     * 
     * @param {string} key - Unique identifier for the cached item
     * @param {Blob|ArrayBuffer} data - Binary data to cache
     * @param {Object} metadata - Optional metadata (version, timestamp, etc.)
     * @returns {Promise<void>}
     * 
     * @example
     * await CacheSystem.set('ffmpeg-core-0.12.10', blobData, {
     *   version: '0.12.10',
     *   size: 31457280,
     *   cachedAt: Date.now()
     * });
     */
    static async set(key, data, metadata = {}) {
        try {
            const db = await this.init();
            if (!db) return; // IndexedDB not available

            return new Promise((resolve, reject) => {
                const transaction = db.transaction([STORE_NAME], "readwrite");
                const store = transaction.objectStore(STORE_NAME);

                // Package data with metadata
                const cacheEntry = {
                    data: data,
                    metadata: {
                        ...metadata,
                        cachedAt: Date.now(),
                        size: data.size || data.byteLength || 0,
                    },
                };

                const request = store.put(cacheEntry, key);

                request.onsuccess = () => {
                    const sizeMB = (cacheEntry.metadata.size / 1024 / 1024).toFixed(2);
                    console.log(`[CacheSystem] Cached: ${key} (${sizeMB} MB)`);
                    resolve();
                };

                request.onerror = (event) => {
                    console.error(`[CacheSystem] Failed to cache ${key}:`, event.target.error);
                    reject(event.target.error);
                };
            });
        } catch (error) {
            console.error("[CacheSystem] Set error:", error);
        }
    }

    /**
     * Retrieve a cached item
     * 
     * @param {string} key - Cache key to retrieve
     * @returns {Promise<Object|null>} Cached entry with data and metadata, or null if not found
     * 
     * @example
     * const cached = await CacheSystem.get('ffmpeg-core-0.12.10');
     * if (cached) {
     *   console.log('Cache hit!', cached.metadata);
     *   const blob = cached.data;
     * }
     */
    static async get(key) {
        try {
            const db = await this.init();
            if (!db) return null;

            return new Promise((resolve, reject) => {
                const transaction = db.transaction([STORE_NAME], "readonly");
                const store = transaction.objectStore(STORE_NAME);
                const request = store.get(key);

                request.onsuccess = (event) => {
                    const result = event.target.result;
                    if (result) {
                        const sizeMB = (result.metadata.size / 1024 / 1024).toFixed(2);
                        console.log(`[CacheSystem] Cache hit: ${key} (${sizeMB} MB)`);
                    } else {
                        console.log(`[CacheSystem] Cache miss: ${key}`);
                    }
                    resolve(result || null);
                };

                request.onerror = (event) => {
                    console.error(`[CacheSystem] Failed to retrieve ${key}:`, event.target.error);
                    resolve(null); // Return null on error (cache miss)
                };
            });
        } catch (error) {
            console.error("[CacheSystem] Get error:", error);
            return null;
        }
    }

    /**
     * Check if a key exists in the cache
     * 
     * @param {string} key - Cache key to check
     * @returns {Promise<boolean>} True if cached, false otherwise
     */
    static async has(key) {
        const entry = await this.get(key);
        return entry !== null;
    }

    /**
     * Remove an item from the cache
     * 
     * @param {string} key - Cache key to delete
     * @returns {Promise<void>}
     */
    static async delete(key) {
        try {
            const db = await this.init();
            if (!db) return;

            return new Promise((resolve, reject) => {
                const transaction = db.transaction([STORE_NAME], "readwrite");
                const store = transaction.objectStore(STORE_NAME);
                const request = store.delete(key);

                request.onsuccess = () => {
                    console.log(`[CacheSystem] Deleted: ${key}`);
                    resolve();
                };

                request.onerror = (event) => {
                    console.error(`[CacheSystem] Failed to delete ${key}:`, event.target.error);
                    reject(event.target.error);
                };
            });
        } catch (error) {
            console.error("[CacheSystem] Delete error:", error);
        }
    }

    /**
     * Clear all cached data
     * Useful for debugging or implementing a "Clear Cache" button
     * 
     * @returns {Promise<void>}
     */
    static async clear() {
        try {
            const db = await this.init();
            if (!db) return;

            return new Promise((resolve, reject) => {
                const transaction = db.transaction([STORE_NAME], "readwrite");
                const store = transaction.objectStore(STORE_NAME);
                const request = store.clear();

                request.onsuccess = () => {
                    console.log("[CacheSystem] All cache cleared");
                    resolve();
                };

                request.onerror = (event) => {
                    console.error("[CacheSystem] Failed to clear cache:", event.target.error);
                    reject(event.target.error);
                };
            });
        } catch (error) {
            console.error("[CacheSystem] Clear error:", error);
        }
    }

    /**
     * Get cache statistics
     * 
     * @returns {Promise<Object>} Statistics about cached items
     */
    static async getStats() {
        try {
            const db = await this.init();
            if (!db) return { count: 0, totalSize: 0, items: [] };

            return new Promise((resolve, reject) => {
                const transaction = db.transaction([STORE_NAME], "readonly");
                const store = transaction.objectStore(STORE_NAME);
                const request = store.getAll();

                request.onsuccess = (event) => {
                    const items = event.target.result || [];
                    const totalSize = items.reduce((sum, item) => sum + (item.metadata?.size || 0), 0);

                    const stats = {
                        count: items.length,
                        totalSize: totalSize,
                        totalSizeMB: (totalSize / 1024 / 1024).toFixed(2),
                        items: items.map((item) => ({
                            size: item.metadata?.size || 0,
                            cachedAt: item.metadata?.cachedAt,
                            version: item.metadata?.version,
                        })),
                    };

                    resolve(stats);
                };

                request.onerror = (event) => {
                    console.error("[CacheSystem] Failed to get stats:", event.target.error);
                    resolve({ count: 0, totalSize: 0, items: [] });
                };
            });
        } catch (error) {
            console.error("[CacheSystem] Stats error:", error);
            return { count: 0, totalSize: 0, items: [] };
        }
    }

    /**
     * Invalidate cache entries older than a specified age
     * 
     * @param {number} maxAgeMs - Maximum age in milliseconds
     * @returns {Promise<number>} Number of entries deleted
     */
    static async invalidateOldEntries(maxAgeMs) {
        try {
            const db = await this.init();
            if (!db) return 0;

            const now = Date.now();
            let deletedCount = 0;

            return new Promise((resolve, reject) => {
                const transaction = db.transaction([STORE_NAME], "readwrite");
                const store = transaction.objectStore(STORE_NAME);
                const request = store.openCursor();

                request.onsuccess = (event) => {
                    const cursor = event.target.result;
                    if (cursor) {
                        const entry = cursor.value;
                        const age = now - (entry.metadata?.cachedAt || 0);

                        if (age > maxAgeMs) {
                            cursor.delete();
                            deletedCount++;
                        }

                        cursor.continue();
                    } else {
                        console.log(`[CacheSystem] Invalidated ${deletedCount} old entries`);
                        resolve(deletedCount);
                    }
                };

                request.onerror = (event) => {
                    console.error("[CacheSystem] Invalidation error:", event.target.error);
                    reject(event.target.error);
                };
            });
        } catch (error) {
            console.error("[CacheSystem] Invalidation error:", error);
            return 0;
        }
    }
}

// Initialize on module load
CacheSystem.init().catch((err) => {
    console.warn("[CacheSystem] Failed to initialize:", err);
});
