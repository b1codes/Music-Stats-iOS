# Implementation Plan: Listening Data Captures & Recently Played Integration

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the "Recently Played" page in the iOS app, retrieve history from Spotify's `/v1/me/player/recently-played` API, and show dynamic recency indicators/badges on top songs and items based on recent plays.

**Tech Stack:** Swift, SwiftUI, iOS SDK

---

## File Map

### New Files
*   `frontend/Music Stats iOS/Music Stats iOS/Tabs/Recently Played/RecentlyPlayedView.swift` — The UI for the new tab displaying the recently played tracks list.
*   `frontend/Music Stats iOS/Music Stats iOS/Tabs/Recently Played/RecentlyPlayedRow.swift` — The custom list row layout for recently played tracks showing the relative timestamp.

### Modified Files
*   `frontend/Music Stats iOS/Music Stats iOS/AuthManager.swift` — Modify scopes to include `user-read-recently-played`.
*   `frontend/Music Stats iOS/Music Stats iOS/Types/IdentifiableTypes.swift` — Add `PlayRecord` struct.
*   `frontend/Music Stats iOS/Music Stats iOS/Types/CodableTypes.swift` — Add `RecentlyPlayedResponse` and parser definitions.
*   `frontend/Music Stats iOS/Music Stats iOS/UserTopItems.swift` — Add `recentlyPlayedList` and the `getRecentlyPlayed()` network call.
*   `frontend/Music Stats iOS/Music Stats iOS/Tabs/TabUIView.swift` — Add the recently played tab page.
*   `frontend/Music Stats iOS/Music Stats iOS/GlassListRow.swift` — Update row UI to accept and display an optional "RECENT" badge or marker.
*   `frontend/Music Stats iOS/Music Stats iOS/Tabs/Top Songs/SongCard.swift` — Check userTopItems' recent list and pass `isRecent` flag to `GlassListRow`.

---

## Task 1: Update Auth Scopes and Models

**Files:**
- Modify: `frontend/Music Stats iOS/Music Stats iOS/AuthManager.swift`
- Modify: `frontend/Music Stats iOS/Music Stats iOS/Types/IdentifiableTypes.swift`
- Modify: `frontend/Music Stats iOS/Music Stats iOS/Types/CodableTypes.swift`

- [ ] **Step 1: Add scope in `AuthManager.swift`**
  Add `user-read-recently-played` to the scopes array or request parameter list during authentication.

- [ ] **Step 2: Add `PlayRecord` struct in `IdentifiableTypes.swift`**
  Add the domain-specific Swift model for play history items (track data + timestamp).

- [ ] **Step 3: Add Decodable types in `CodableTypes.swift`**
  Add `RecentlyPlayedResponse` and JSON decoding mappings.

- [ ] **Step 4: Commit changes**
  ```bash
  git add "frontend/Music Stats iOS/Music Stats iOS/AuthManager.swift" \
          "frontend/Music Stats iOS/Music Stats iOS/Types/IdentifiableTypes.swift" \
          "frontend/Music Stats iOS/Music Stats iOS/Types/CodableTypes.swift"
  git commit -m "feat(models): add PlayRecord models and request user-read-recently-played scope"
  ```

---

## Task 2: Implement Data Fetching in UserTopItems

**Files:**
- Modify: `frontend/Music Stats iOS/Music Stats iOS/UserTopItems.swift`

- [ ] **Step 1: Add `@Published var recentlyPlayedList: [PlayRecord]`**
  Define a new array in the state container.

- [ ] **Step 2: Implement `getRecentlyPlayed()` API fetch**
  Write an async function calling `https://api.spotify.com/v1/me/player/recently-played?limit=50`. Parse the response and map to `PlayRecord` structs.

- [ ] **Step 3: Update `fetchAll()` and `retry()`**
  Incorporate `getRecentlyPlayed()` in the main async loading sequence.

- [ ] **Step 4: Commit changes**
  ```bash
  git add "frontend/Music Stats iOS/Music Stats iOS/UserTopItems.swift"
  git commit -m "feat(data): implement Recently Played API fetch in UserTopItems"
  ```

---

## Task 3: Build Recently Played UI & Tab

**Files:**
- Create: `frontend/Music Stats iOS/Music Stats iOS/Tabs/Recently Played/RecentlyPlayedView.swift`
- Create: `frontend/Music Stats iOS/Music Stats iOS/Tabs/Recently Played/RecentlyPlayedRow.swift`
- Modify: `frontend/Music Stats iOS/Music Stats iOS/Tabs/TabUIView.swift`

- [ ] **Step 1: Create `RecentlyPlayedRow.swift`**
  Design a custom Glassmorphic row that displays the artwork, track name, artists, and the relative played time (e.g. "20m ago").

- [ ] **Step 2: Create `RecentlyPlayedView.swift`**
  Design the main feed using `ScrollView` and `LazyVStack` showing the chronological list. Integrate `StateContainerView` for load and error states.

- [ ] **Step 3: Embed in `TabUIView.swift`**
  Add a new tab element `RecentlyPlayedView(userTopItems: userTopItems)` at the 4th position using the `clock.arrow.circlepath` SF Symbol.

- [ ] **Step 4: Commit changes**
  ```bash
  git add "frontend/Music Stats iOS/Music Stats iOS/Tabs/Recently Played/" \
          "frontend/Music Stats iOS/Music Stats iOS/Tabs/TabUIView.swift"
  git commit -m "feat(ui): build Recently Played tab feed and row design"
  ```

---

## Task 4: Add Recency Badges on Top Songs

**Files:**
- Modify: `frontend/Music Stats iOS/Music Stats iOS/GlassListRow.swift`
- Modify: `frontend/Music Stats iOS/Music Stats iOS/Tabs/Top Songs/SongCard.swift`

- [ ] **Step 1: Update `GlassListRow.swift` to support optional recency badge**
  Add `var isRecent: Bool = false` to initialization. If true, render a subtle tag (e.g. a small capsule badge with text "RECENT" in `dsInkPrimary` on a background of `Color.dsThermalCorona` with 0.8 opacity) to the right of the title.

- [ ] **Step 2: Update `SongCard.swift` to pass `isRecent` flag**
  Check if `song.spotifyId` matches any track ID in `userTopItems.recentlyPlayedList` played within the last 12 hours. Pass this boolean to `GlassListRow`.

- [ ] **Step 3: Commit changes**
  ```bash
  git add "frontend/Music Stats iOS/Music Stats iOS/GlassListRow.swift" \
          "frontend/Music Stats iOS/Music Stats iOS/Tabs/Top Songs/SongCard.swift"
  git commit -m "feat(ui): add recency indicators to Top Songs based on play history"
  ```
