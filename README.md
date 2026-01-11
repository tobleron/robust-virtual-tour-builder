# Remax Virtual Tour Builder (VTB)

A high-performance, professional-grade virtual tour creation platform designed for real estate and immersive space documentation. This application combines a fluid web-based frontend with a powerful Rust-driven backend to deliver seamless panoramic processing and tour management.

**Directing Developer:** Arto Kalishian  
**Release Date:** January 5, 2026

---

## 🚀 Overview

Remax VTB is a comprehensive suite for building, editing, and exporting interactive 360° virtual tours. It leverages modern web technologies (React patterns, Tailwind CSS, Pannellum) and a high-performance Rust backend to handle heavy lifting like image optimization and video encoding.

## ✨ Key Features

- **Advanced Panorama Viewer**: Interactive 360° viewing experience powered by Pannellum.
- **Smart Upload Processor**: Parallelized image processing with checksum-based duplicate detection.
- **Rich Interactive Hotspots**: Link scenes together with precise "Director View" camera transitions.
- **Project Persistence**: Local storage and state management to ensure work is never lost.
- **High-Performance Backend**:
    - **Image Optimization**: Automatic resizing and compression using Rust.
    - **EXIF Analysis**: Deep metadata extraction for camera calibration.
    - **Fast Video Encoding**: Integrated FFmpeg support for high-quality transitions.
- **Comprehensive Exporting**: Export self-contained tours with all assets and a portable HTML player.
- **Modern UI/UX**: Compact, intuitive sidebar navigation with real-time state updates and Material Design principles.

## 🏗️ Architecture

### Frontend
- **Framework**: Modern Vanilla JavaScript with a centralized `store.js` state management.
- **Styling**: Tailwind CSS 4.0 for a responsive and accessible interface.
- **Libraries**: Pannellum (Viewer), JSZip (Exporting), FileSaver.js.

### Backend (Rust)
- **Engine**: Actix-web for high-concurrency request handling.
- **Image Processing**: `image` and `rayon` crates for multi-threaded optimization.
- **Metadata**: `kamadak-exif` for professional-grade metadata extraction.
- **Utilities**: FFmpeg integration for video-related operations.

## 🛠️ Installation & Setup

### Prerequisites
- **Node.js**: v18+ (for frontend dev server and Tailwind)
- **Rust**: Edition 2024 (for backend processing)
- **FFmpeg**: Required for video encoding features.

### Development Environment

**Recommended (All-in-one):**
```bash
# Start backend, Tailwind watcher, and frontend (port 9999)
./start_dev.sh
```

**Manual Setup:**
1. **Frontend**:
   ```bash
   npm install
   npm run dev
   ```
2. **Backend**:
   ```bash
   cd backend
   cargo run --release
   ```
3. **Tailwind Watcher**:
   ```bash
   npm run css:watch
   ```

## 📁 Project Structure

- `backend/`: Rust source code, handlers, and binary dependencies.
- `src/`: Core frontend logic.
    - `components/`: UI modules (Viewer, Sidebar, HotspotManager).
    - `systems/`: Business logic (VideoEncoder, Exporter, NavigationSystem).
    - `utils/`: Diagnostic and helper utilities (Logger, Debug, NotificationSystem).
- `docs/`: All project documentation (features, security, releases, guides).
- `css/`: Tailwind and custom style overrides.
- `ai_guidelines.md`: High-level AI development rules and project philosophy.
- `.agent/workflows/`: Step-by-step procedures for AI agents (commits, pre-push, security).

## ⚖️ License

Copyright © 2026 Arto Kalishian. All rights reserved.
