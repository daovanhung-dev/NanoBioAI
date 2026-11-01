# NanoBio Admin Web

React, Vite, and TypeScript SPA for super administrators to find and manage user accounts and Plus entitlements.

## Local development

1. Install Node.js 20 or newer and run `npm install`.
2. For a local backend, start it from `backend/` with `uv run uvicorn nanobio_backend.main:app --reload --host 127.0.0.1 --port 8000`.
3. For the Ubuntu backend, open an SSH tunnel in a separate terminal:

   ```bash
   ssh -N -o StrictHostKeyChecking=yes -o ExitOnForwardFailure=yes -L 127.0.0.1:8000:127.0.0.1:8000 nanobio@100.86.238.91
   ```

   Keep that terminal open while using the Admin Web. SSH carries the connection to the backend's loopback interface; do not put SSH credentials in `.env.local`.
4. Run `npm run dev` from `admin-web/`. The Vite proxy sends `/api/v1` and `/health` to `127.0.0.1:8000`; set `VITE_API_PROXY_TARGET` in `.env.local` only when the backend listens on a different reachable origin.

For a same-origin deployment, leave `VITE_API_BASE_URL` empty and route `/api/v1` and `/health` to the backend. For a separate HTTPS API origin, set `VITE_API_BASE_URL` at build time.

The browser stores the rotating login session in `sessionStorage`. The app requires `super_admin` and checks `/health/ready` before enabling writes. It does not contain production credentials and is not deployed by this project change.
