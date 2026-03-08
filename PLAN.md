# NordLynx WireGuard Config Generator — Premium iOS Utility

## Overview
A sleek, premium iOS utility that fetches NordVPN server recommendations and generates WireGuard `.conf` and OpenVPN `.ovpn` files ready for export. Dark-themed, translucent UI with smooth animations — feels like a first-party Apple tool.

> **Note:** Your project is set up as an iOS app (not macOS), so instead of saving to Desktop, configs will be saved to the app's documents folder and exportable via the iOS Share Sheet or Files app.

---

### **Features**
- [x] Enter how many server configs to generate (1–50) with a clean number input
- [x] Tap "Generate" to fetch optimized NordVPN server recommendations via their API
- [x] Each server's WireGuard public key, hostname, and IP are parsed automatically
- [x] Generates a properly formatted `.conf` file per server using your exact template
- [x] View all generated configs in a list with server name, IP, and country info
- [x] Export all configs at once via the iOS Share Sheet (AirDrop, Files, etc.)
- [x] Export individual configs by tapping on them
- [x] Clear loading state with animated progress indicator
- [x] Success/error feedback with haptics and animated status icons
- [x] Country and city-specific filtering
- [x] WireGuard UDP, OpenVPN UDP, and OpenVPN TCP protocol support
- [x] Multiple export formats: Individual files, ZIP, Merged Text, JSON, CSV
- [x] Named access key system with preset keys (Nick, Poli) and custom key support
- [x] Key picker UI to switch between access keys instantly
- [x] Bulletproof retry logic with exponential backoff and jitter
- [x] Cancellation-safe async operations
- [x] Search/filter within generated configs

### **Access Keys**
- **Nick** (preset): `e9f2abb927fb478e7c61afed90ee4cae8e3094b47418748ea7e518c955a0a0d1`
- **Poli** (preset): `e9f2ab075820d8ccc3362eadc4bbadb335571961002b5d5d606cbe4083680625`
- Custom keys can be added, named, and persisted via UserDefaults

### **Design**
- **Dark theme** with deep black MeshGradient background and subtle translucent materials
- Monospaced font accents for the "technical utility" vibe — config previews in SF Mono
- Teal/cyan accent color for WireGuard, orange for OpenVPN protocols
- Large bold title at top: "NordLynx Generator" with active key badge
- Frosted glass-style cards (`.ultraThinMaterial`) for the input area and results
- SF Symbol animations — bouncing shield icon on success, pulsing during loading
- Smooth spring animations for list items appearing with staggered delay
- Haptic feedback on generate, export, and key switch actions

### **Screens**
- **Main screen** with sections:
  1. **Header** — App title with shield icon and active key badge
  2. **Input section** — Protocol picker, country/city filter, server count stepper, Generate button
  3. **Results section** — Loading → config list with search → export format picker
- **Config Detail Sheet** — Server metadata grid + config file preview + copy/share actions
- **Access Key Settings Sheet** — Key picker with Nick/Poli presets, custom key management
- **Share Sheet** — Native iOS share sheet for config export

### **App Icon**
- Dark gradient background (deep navy to teal/cyan)
- A stylized shield or lock symbol in white/cyan, evoking VPN security
- Clean, minimal, premium feel

---

### **Technical Notes**
- Uses `@Observable` pattern with async/await networking
- Named access key system with preset and custom key support via UserDefaults
- Service ID: `HEVpnj1BCmWLoddTkN9fSedR`
- Configs saved to app documents directory, exported via `ShareLink`
- Ephemeral URLSession with retry logic (3 attempts, exponential backoff)
- URLComponents for safe URL construction
- Task cancellation support throughout async operations
- `nonisolated` on all Codable/data types for Swift concurrency compliance
