# Running Fasha Locally

Everything you need to go from "laptop just started, everything is off" to
"the app is running on my phone." Written for **PowerShell** (Windows'
default terminal). If you use Git Bash instead, swap `.\mvnw.cmd` for
`./mvnw`.

You'll end up with **3 terminal windows open at once** (database, backend,
and the app itself) - that's normal. Closing any of them stops that piece.

---

## Quick reference

Run these in order, each time you start fresh after a reboot.

**1. Start Docker Desktop** (the application itself, from the Start Menu) and
wait until it says "Docker Desktop is running" (check the system tray icon).

**2. Terminal 1 - start the database:**
```powershell
cd D:\FLUTTER\Fasha
docker compose up -d
```

**3. Terminal 2 - start the backend:**
```powershell
cd D:\FLUTTER\Fasha\backend
.\mvnw.cmd spring-boot:run
```
Wait for `Started BackendApplication` in the log before moving on. **Leave
this terminal open** - closing it stops the API.

**4. Plug in your phone via USB**, then in Terminal 3:
```powershell
cd D:\FLUTTER\Fasha\mobile
flutter devices
```
Find your phone in the list and note its device id (a string of digits,
e.g. `5706003186`).

**5. Forward the backend port to your phone over USB** (run this every
single time you reconnect the phone - it doesn't persist across
unplug/replug):
```powershell
adb reverse tcp:8081 tcp:8081
```

**6. Run the app on your phone:**
```powershell
flutter run -d <device-id-from-step-4>
```

The app should open on your phone within a minute or two. Leave this
terminal open too - it's your live connection to the running app (press
`r` for hot reload, `R` for hot restart, `q` to quit).

---

## Step-by-step, with explanations

### 1. Docker Desktop
The backend needs PostgreSQL, which runs inside a Docker container -
Docker Desktop is what actually runs containers on Windows. If it's not
running, `docker compose up -d` in the next step will fail with a
connection error.

### 2. Start PostgreSQL
```powershell
docker compose up -d
```
This starts (or resumes) the `fasha-postgres` container in the
background. Your data persists between restarts (it's stored in a Docker
volume) unless you explicitly run `docker compose down -v`, which wipes it.

Verify it's actually up:
```powershell
docker ps
```
You should see `fasha-postgres` in the list, healthy.

### 3. Start the backend
```powershell
cd backend
.\mvnw.cmd spring-boot:run
```
This compiles and runs the Spring Boot API on **port 8081**. First boot
after a reboot can take 10-30 seconds. You'll know it's ready when you see:
```
Started BackendApplication in X.XXX seconds
```
Quick sanity check from any terminal:
```powershell
curl http://localhost:8081/api/categories
```
This should return a JSON list of categories, not an error.

### 4. Connect your phone
Plug the phone in via USB. Make sure:
- Developer options → **USB debugging** is turned on
- You've tapped **Allow** on the "Allow USB debugging?" popup that appears
  on the phone's screen

Then confirm it's visible:
```powershell
adb devices
```
It should list your phone with status `device` (not `unauthorized` - if
you see that, check the phone screen for the Allow popup again).

### 5. Forward the port
```powershell
adb reverse tcp:8081 tcp:8081
```
The app is built to always call `http://localhost:8081` - on a phone,
"localhost" normally means the phone itself, not your PC. This command
makes the phone's own `localhost:8081` transparently forward to your PC's
backend over the USB cable. **It resets every time the phone disconnects**,
so re-run it after any unplug/replug or reboot.

### 6. Run the app
```powershell
cd mobile
flutter run -d <device-id>
```
First run after a reboot rebuilds things and can take a minute or two;
after that it's much faster.

---

## Alternative: test in a browser instead of your phone

Faster for quick checks when you don't want to deal with USB at all:
```powershell
cd mobile
flutter run -d chrome --web-port=5173
```
Then open `http://localhost:5173` if it doesn't open automatically. Only
needs steps 1-3 above (Docker + backend) - no phone, no `adb reverse`.

---

## Shutting everything down

- In the `flutter run` terminal: press `q`, or `Ctrl+C`
- In the backend terminal: `Ctrl+C`
- Database: you can just leave `fasha-postgres` running (it's cheap and
  idle in the background), or stop it with:
  ```powershell
  docker compose down
  ```
  (this keeps your data; only `docker compose down -v` deletes it)
- Docker Desktop itself can stay running, or be closed from the system tray

Next time you start your laptop, just repeat the Quick Reference steps
from the top.

---

## Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| `docker compose up -d` fails / connection error | Docker Desktop isn't actually running yet - open it and wait for the tray icon to settle |
| Backend fails to start with a DB connection error | Same as above, or `docker ps` doesn't show `fasha-postgres` healthy yet - give it a few seconds and retry |
| `adb devices` shows nothing at all | Check the phone's notification shade for the USB mode - switch it to **File Transfer**, not "charging only." Try a different cable (some are charge-only) |
| `adb devices` shows `unauthorized` | The "Allow USB debugging?" popup is waiting on the phone's screen - unlock it and tap Allow |
| App installs but can't reach the backend (network errors on every screen) | You forgot to re-run `adb reverse tcp:8081 tcp:8081` after reconnecting the phone |
| Port `5433` or `8081` already in use | Something else on your machine is using it - see the comments in `docker-compose.yml` and `backend/src/main/resources/application.yml` for how to change the ports (`DB_PORT`, `SERVER_PORT`) |
| `flutter devices` doesn't list your phone | Run `flutter doctor` to check the Android toolchain is still green; try `adb kill-server` then `adb start-server` |
