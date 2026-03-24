<p align="center">
  <img src="https://raw.githubusercontent.com/sk7n4k3d/fedispace/master/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" width="120" alt="FediSpace Logo"/>
</p>

<h1 align="center">FediSpace</h1>

<p align="center">
  <strong>An AI-enhanced, premium Pixelfed client built with Flutter</strong>
</p>

<p align="center">
  <a href="https://github.com/sk7n4k3d/fedispace/actions/workflows/ci.yml"><img src="https://github.com/sk7n4k3d/fedispace/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://github.com/sk7n4k3d/fedispace/releases"><img src="https://img.shields.io/github/v/release/sk7n4k3d/fedispace?style=for-the-badge&color=00d4ff&labelColor=0a0e1a" alt="Release"></a>
  <a href="https://github.com/sk7n4k3d/fedispace/blob/master/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge&color=00d4ff&labelColor=0a0e1a" alt="License"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white&labelColor=0a0e1a" alt="Flutter"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white&labelColor=0a0e1a" alt="Dart"></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/AI_Powered-OpenAI_Compatible-ff6b6b?style=for-the-badge&labelColor=0a0e1a" alt="AI Powered">
  <img src="https://img.shields.io/badge/16_Languages-Supported-success?style=for-the-badge&color=00ff88&labelColor=0a0e1a" alt="16 Languages">
  <img src="https://img.shields.io/badge/Android-Ready-success?style=for-the-badge&color=3ddc84&labelColor=0a0e1a" alt="Android">
  <img src="https://img.shields.io/badge/Push_Notifications-UnifiedPush-blueviolet?style=for-the-badge&labelColor=0a0e1a" alt="Push Notifications">
</p>

---

## About

**FediSpace** is an AI-supercharged, Instagram-inspired client for [Pixelfed](https://pixelfed.org/) -- the federated, privacy-friendly image sharing platform. It takes the original Pixelfed experience and boosts it with artificial intelligence: real-time post translation, AI-powered image editing, smart content discovery, and more -- all wrapped in a cyberpunk-inspired dark theme with smooth animations.

---

## AI-Powered Features

FediSpace integrates AI at the core of the experience. You are not locked into any cloud provider.

### Bring Your Own AI -- Local or Cloud

FediSpace works with **any OpenAI-compatible API**:

| Provider | Type | Example |
|---|---|---|
| [Ollama](https://ollama.ai) | Local LLM | Llama 3, Mistral, Gemma on your own machine |
| [LM Studio](https://lmstudio.ai) | Local LLM | One-click local models with OpenAI-compatible server |
| [LocalAI](https://localai.io) | Self-hosted | Docker-based, drop-in OpenAI replacement |
| [OpenAI](https://openai.com) | Cloud | GPT-4o, GPT-4 Turbo |
| Any compatible API | Custom | Groq, Together AI, Mistral API, vLLM, etc. |

> **100% privacy-friendly:** Point FediSpace to your local Ollama instance and your data never leaves your network.

### What AI Does

| Feature | Description |
|---|---|
| **Auto-Translate Posts** | Instantly translate any post into your language |
| **AI Image Editing** | Describe what you want changed and AI transforms your photos |
| **Smart Translation Settings** | Configure auto-translate, choose target language, or translate on demand |
| **16 Language UI** | The entire app interface adapts to your language |

---

## Features

### Timeline and Posts
- Instagram-style feed with infinite scroll and blur hash placeholders
- Full-screen image viewer with pinch-to-zoom
- Video playback with custom player controls
- Carousel/gallery posts support
- Like, comment, share, bookmark -- full social interactions
- Post detail page with threaded replies
- View edit history of modified posts

### Reels / Loops (NEW)
- Dedicated Loops instance integration
- Separate OAuth login for Loops content
- Vertical video feed with auto-play
- Full-screen immersive video experience

### Multi-Account (NEW)
- Add and switch between multiple Pixelfed accounts
- Per-account settings and preferences
- Quick account switcher in navigation

### Post Creation (NEW)
- Gallery, Camera, and Video capture options
- Photo filters and AI-powered image editing
- Post drafts -- save and resume later
- Story creation from gallery or camera

### Stories
- Story bar with avatar bubbles
- Full-screen story viewer with progress indicators
- Story creation from camera or gallery
- AI-powered image editing with creative filters
- Viewer count and list for your own stories
- Story replies and auto-advance navigation

### Discover and Search
- Explore page with trending content
- User search with real-time results
- Hashtag search and tag-based timelines
- Account discovery across the Fediverse

### Direct Messages
- Conversation list with unread indicators
- Real-time messaging interface
- Image/photo sharing in conversations (NEW)
- New message with user search and recipient picker
- Delete conversations with confirmation dialogs

### Notifications
- Real-time push notifications via [UnifiedPush](https://unifiedpush.org/)
- In-app notification polling with badge counts (NEW)
- Notification types: follows, likes, boosts, mentions, polls
- Clear all with confirmation
- Tap to navigate directly to relevant content

### Profile and Social
- Rich user profiles with stats
- Profile editing capabilities
- QR code profile sharing (NEW)
- Follow / Unfollow / Mute / Block actions
- Report users with reason description
- Follow requests management
- Followers and following lists with pagination

### Settings and Privacy
- Content filters -- create and manage keyword filters
- Muted and blocked accounts management
- Domain blocks -- block entire instances
- Bookmarks, liked posts, archived posts
- Collections -- organize posts into collections

### Internationalization (i18n)
Full multi-language support with 16 languages:

English, French, Spanish, German, Italian, Portuguese, Dutch, Russian, Chinese, Japanese, Korean, Arabic, Hindi, Turkish, Polish, Ukrainian

- In-app language picker
- System locale detection
- Persistent preference

### UI and Design
- Cyberpunk dark theme with neon accents, glassmorphism, gradients
- Instagram-inspired layout with familiar navigation
- Custom bottom navigation with animated transitions
- Pull-to-refresh on all list views
- Smooth loading indicators and skeleton screens
- Responsive design across different screen sizes

---

## Tech Stack

| Technology | Purpose |
|---|---|
| **Flutter / Dart** | Cross-platform framework |
| **OAuth2** | Secure authentication |
| **UnifiedPush** | Decentralized push notifications |
| **SharedPreferences** | Local settings persistence |
| **CachedNetworkImage** | Image caching and blur hash |
| **Camera** | Photo and video capture |
| **Flutter Secure Storage** | Encrypted credential storage |

---

## Installation

### Prerequisites
- Flutter SDK >=3.0.0
- Android SDK (API 24+)
- A Pixelfed instance account

### Build from source

```bash
git clone https://github.com/sk7n4k3d/fedispace.git
cd fedispace
flutter pub get
flutter run
flutter build apk --release
```

### Download
Check the [Releases](https://github.com/sk7n4k3d/fedispace/releases) page for pre-built APKs.

---

## Project Structure

```
lib/
  core/           API, auth, notifications, logging, translation
  l10n/           Internationalization (16 languages)
  models/         Data models (Account, Status, Story, etc.)
  routes/         Pages and screens
    bookmarks/    Saved posts
    followers/    Follow lists
    liked/        Liked posts
    messages/     Direct messages
    notifications/
    post/         Post creation and detail
    profile/      Profile, collections, archives, QR
    reels/        Loops/Reels video feed
    search/       Discover and search
    settings/     Settings, filters, blocks
    timeline/     Main feed
  themes/         Cyberpunk theme
  widgets/        Reusable components
  main.dart       App entry point
```

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: Add amazing feature'`)
4. Push to the branch (`git push origin feat/amazing-feature`)
5. Open a Pull Request

---

## Credits

| Resource | Description |
|---|---|
| [Pixelfed](https://pixelfed.org/) | The federated image sharing platform |
| [UnifiedPush](https://unifiedpush.org/) | Decentralized push notification protocol |
| [Feathr](https://github.com/feathr-space/feathr) | Original project base |

---

## License

MIT License -- Copyright (c) 2024-2026 sk7n4k3d

See [LICENSE](LICENSE) for full text.
