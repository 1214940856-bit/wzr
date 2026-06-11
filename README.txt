EVAN portfolio prototype

Local preview
1. Run: powershell -ExecutionPolicy Bypass -File .\start-local.ps1
2. Open: http://127.0.0.1:4173/
3. Refresh the browser after editing index.html.

Publishing
1. Edit the root index.html and assets directory only.
2. Run: powershell -ExecutionPolicy Bypass -File .\optimize-images.ps1
3. Run: powershell -ExecutionPolicy Bypass -File .\optimize-videos.ps1
4. Run: powershell -ExecutionPolicy Bypass -File .\sync-dist.ps1
5. Run: powershell -ExecutionPolicy Bypass -File .\check-dist.ps1
6. Deploy the dist directory after verifying the preview.

Notes
- dist is generated for publishing. Do not edit dist/index.html directly.
- sync-dist.ps1 copies only assets referenced by index.html, keeping source-only files out of deploys.
- optimize-images.ps1 keeps the high-resolution poster sources and regenerates lightweight web versions.
- optimize-videos.ps1 keeps the original videos and regenerates lightweight H.264 web versions.
- check-dist.ps1 blocks deploys while referenced files larger than 10 MB remain.
- Videos load only after a visitor clicks "加载并播放".
- serve.py supports video byte ranges for local streaming.
- The Netlify production site remains paused until its account usage resets or the plan is upgraded.
