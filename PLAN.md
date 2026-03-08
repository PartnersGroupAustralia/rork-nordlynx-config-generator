# NordLynx WireGuard Config Generator — Premium iOS Utility

## Overview
A sleek, premium iOS utility that fetches NordVPN server recommendations and generates WireGuard `.conf` files ready for export. Dark-themed, translucent UI with smooth animations — feels like a first-party Apple tool.

> **Note:** Your project is set up as an iOS app (not macOS), so instead of saving to Desktop, configs will be saved to the app's documents folder and exportable via the iOS Share Sheet or Files app.

---

### **Features**
- Enter how many server configs to generate (1–50) with a clean number input
- Tap "Generate" to fetch optimized NordVPN server recommendations via their API
- Each server's WireGuard public key, hostname, and IP are parsed automatically
- Generates a properly formatted `.conf` file per server using your exact template
- View all generated configs in a list with server name, IP, and country info
- Export all configs at once via the iOS Share Sheet (AirDrop, Files, etc.)
- Export individual configs by tapping on them
- Clear loading state with animated progress indicator
- Success/error feedback with haptics and animated status icons

### **Design**
- **Dark theme** with deep black background and subtle translucent materials
- Monospaced font accents for the "technical utility" vibe — config previews in SF Mono
- Teal/cyan accent color to match the NordVPN/WireGuard identity
- Large bold title at top: "NordLynx Generator"
- Frosted glass-style cards (`.ultraThinMaterial`) for the input area and results
- SF Symbol animations — bouncing shield icon on success, pulsing during loading
- Smooth spring animations for list items appearing with staggered delay
- Haptic feedback on generate and export actions

### **Screens**
- **Single screen** with two sections:
  1. **Top section** — App title with shield icon, number-of-configs stepper/field, and a prominent "Generate Configs" button
  2. **Bottom section** — Results area that shows: loading spinner during fetch → list of generated configs on success → error message on failure
- **Share Sheet** — Native iOS share sheet appears when exporting configs
- Tapping a config row shows a detail preview of the `.conf` file contents

### **App Icon**
- Dark gradient background (deep navy to teal/cyan)
- A stylized shield or lock symbol in white/cyan, evoking VPN security
- Clean, minimal, premium feel

---

### **Technical Notes**
- Uses `@Observable` pattern with async/await networking
- Hardcoded credentials as specified (SERVICE_ID and PRIVATE_KEY)
- Configs saved to app documents directory, exported via `ShareLink` / `UIActivityViewController`
- Removes the existing SwiftData boilerplate (Item model, model container) — not needed
