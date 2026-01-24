/* src/systems/TourTemplateAssets.res */

/* Index page template for exported tour packages */

let indexTemplate = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>__TOUR_NAME__ - Virtual Tour Hub</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <style>
        :root {
            --primary: #003da5;
            --primary-dark: #002a70;
            --slate-900: #020617;
            --slate-800: #0f172a;
            --slate-700: #1e293b;
            --glass: rgba(255, 255, 255, 0.03);
            --glass-border: rgba(255, 255, 255, 0.08);
            --warning: #f59e0b;
            --info: #3b82f6;
            --success: #10b981;
            --slate-600: #475569;
            --slate-400: #94a3b8;
            --slate-200: #e2e8f0;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0; padding: 0;
            font-family: 'Outfit', sans-serif;
            background: var(--slate-900);
            color: white;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            overflow-x: hidden;
        }
        .background-blob {
            position: fixed; width: 800px; height: 800px;
            background: radial-gradient(circle, rgba(0, 61, 165, 0.1) 0%, rgba(0, 0, 0, 0) 70%);
            z-index: -1; filter: blur(80px); pointer-events: none;
        }
        .blob-1 { top: -200px; left: -200px; }
        .blob-2 { bottom: -200px; right: -200px; background: radial-gradient(circle, rgba(15, 23, 42, 0.3) 0%, rgba(0, 0, 0, 0) 70%); }
        .container {
            width: 90%; max-width: 1000px; text-align: center; padding: 60px 0;
            animation: fadeIn 1s cubic-bezier(0.22, 1, 0.36, 1);
        }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(30px); } to { opacity: 1; transform: translateY(0); } }
        .header { margin-bottom: 60px; position: relative; }
        .logo-container {
            display: inline-flex; align-items: center; justify-content: center;
            background: white; padding: 4px; border-radius: 12px;
            margin-bottom: 32px; box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            max-width: 120px; max-height: 60px; overflow: hidden;
        }
        .logo-container img { width: 100%; height: auto; display: block; object-fit: contain; }
        h1 { font-size: 42px; font-weight: 700; margin: 0 0 16px 0; }
        .version-badge {
            display: inline-flex; align-items: center; gap: 8px; background: var(--glass);
            padding: 6px 16px; border-radius: 100px; font-size: 13px; font-weight: 600; color: var(--slate-400);
        }
        .grid {
            display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 32px; margin-top: 20px;
        }
        .card {
            background: var(--slate-800); border: 1px solid var(--glass-border); border-radius: 24px;
            padding: 40px 30px; text-decoration: none; color: white; display: flex; flex-direction: column;
            align-items: center; gap: 20px; position: relative; overflow: hidden; transition: all 0.4s;
        }
        .card:hover { transform: translateY(-12px); background: var(--slate-700); }
        .icon { font-size: 48px; }
        .card-4k .icon { color: var(--warning); } .card-2k .icon { color: var(--info); } .card-hd .icon { color: var(--success); }
        .res-label { font-size: 26px; font-weight: 700; }
        .description { font-size: 15px; color: var(--slate-400); line-height: 1.6; }
        .btn {
            margin-top: 10px; background: rgba(255, 255, 255, 0.05); color: var(--slate-200);
            padding: 12px 32px; border-radius: 100px; font-size: 14px; font-weight: 600;
        }
        .card:hover .btn { background: white; color: #0f172a; }
        .footer { margin-top: 80px; font-size: 13px; color: var(--slate-600); }
    </style>
</head>
<body>
    <div class="background-blob blob-1"></div>
    <div class="background-blob blob-2"></div>
    <div class="container">
        <div class="header">
            <div class="logo-container"><img src="tour_4k/assets/logo.png" onerror="this.parentElement.style.display='none'"></div>
            <h1>__TOUR_NAME_PRETTY__</h1>
            <div class="version-badge">Virtual Tour v__VERSION__</div>
        </div>
        <div class="grid">
            <a href="tour_4k/index.html" class="card card-4k">
                <span class="material-icons icon">high_quality</span>
                <span class="res-label">4K Ultra HD</span>
                <span class="description">Best for high-end displays.</span>
                <span class="btn">Launch Tour</span>
            </a>
            <a href="tour_2k/index.html" class="card card-2k">
                <span class="material-icons icon">monitor</span>
                <span class="res-label">2K Desktop</span>
                <span class="description">Optimized for laptops.</span>
                <span class="btn">Launch Tour</span>
            </a>
            <a href="tour_hd/index.html" class="card card-hd">
                <span class="material-icons icon">smartphone</span>
                <span class="res-label">HD Mobile</span>
                <span class="description">Portrait layout for phones.</span>
                <span class="btn">Launch Tour</span>
            </a>
        </div>
        <div class="footer">&copy; __YEAR__ Virtual Tour Platform.</div>
    </div>
</body>
</html>`

let generateExportIndex = (tourName, version) => {
  let prettyName = String.replaceRegExp(tourName, /_/g, " ")
  let year = Date.make()->Date.getFullYear->Belt.Int.toString

  indexTemplate
  ->String.replaceRegExp(/__TOUR_NAME__/g, tourName)
  ->String.replaceRegExp(/__TOUR_NAME_PRETTY__/g, prettyName)
  ->String.replaceRegExp(/__VERSION__/g, version)
  ->String.replaceRegExp(/__YEAR__/g, year)
}

let generateEmbedCodes = (tourName, version) => {
  `VIRTUAL TOUR - EMBED CODES
Version: ${version}
Property: ${tourName}

1. 4K (Desktop):
   <iframe src="tour_4k/index.html" width="100%" height="640" style="border:none;" title="360° Virtual Tour - ${tourName}"></iframe>

2. 2K (Desktop):
   <iframe src="tour_2k/index.html" width="100%" height="400" style="border:none;" title="360° Virtual Tour - ${tourName}"></iframe>

3. HD (Mobile):
   <iframe src="tour_hd/index.html" width="375" height="667" style="border:none;" title="360° Virtual Tour - ${tourName}"></iframe>
`
}
