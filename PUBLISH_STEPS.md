# Portfolio Publish Steps

Use this flow whenever the portfolio has been changed and you want
https://wwwlf-zuopingji.xyz to show the latest version.

## One-Command Publish

From this project folder, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\publish-to-github.ps1
```

Optional custom commit message:

```powershell
powershell -ExecutionPolicy Bypass -File .\publish-to-github.ps1 -Message "Update portfolio content"
```

The script will:

1. Copy the latest `index.html`, deployment scripts, GitHub Pages workflow, and referenced assets into the clean GitHub sync folder.
2. Build and validate `dist`.
3. Commit the changes if there are any.
4. Push to GitHub `main`.
5. Trigger GitHub Pages deployment.

## After Publishing

1. Open GitHub Actions:
   https://github.com/1214940856-bit/wzr/actions
2. Wait for `Deploy portfolio to GitHub Pages` to show a green check.
3. Open:
   https://wwwlf-zuopingji.xyz?v=latest

If the page looks old, press `Ctrl + F5` or add a timestamp query like:

```text
https://wwwlf-zuopingji.xyz?v=20260613
```

## Important

- The live domain is `wwwlf-zuopingji.xyz`.
- Do not use `www.lf-zuopingji.xyz`; that is a different domain.
- Cloudflare DNS should keep these four GitHub Pages A records:
  - `185.199.108.153`
  - `185.199.109.153`
  - `185.199.110.153`
  - `185.199.111.153`
- Keep Cloudflare proxy status as `DNS only` for these records.
