# Design Specification: Listening Data Captures & Recently Played Integration

## 1. Overview & Context

This design specification details the integration of Spotify's **Recently Played** endpoint and outlines strategies for capturing user listening data more comprehensively. Currently, the app relies solely on Spotify's top tracks/artists endpoints, which provide aggregated, long-term views but lack real-time history, exact playback timestamps, and fine-grained recency data.

Integrating the recently played history will allow:
1. A new **Recently Played** dashboard/feed in the UI showing the user's exact track history.
2. Dynamic **recency badges/indicators** on top songs and items to show if they have been played recently.
3. Foundations for long-term listening history collection.

---

## 2. Spotify API Endpoint Analysis

### Recently Played Endpoint
*   **Endpoint:** `GET https://api.spotify.com/v1/me/player/recently-played`
*   **OAuth Scope Required:** `user-read-recently-played`
*   **Rate Limits:** Subject to standard Spotify Web API rate limits.
*   **Query Parameters:**
    *   `limit`: Integer (1-50, default 20).
    *   `after`: Unix millisecond timestamp. Returns tracks played *after* this time. (Mutually exclusive with `before`).
    *   `before`: Unix millisecond timestamp. Returns tracks played *before* this time.
*   **Response Payload Structure:**
    ```json
    {
      "items": [
        {
          "track": {
            "id": "2TpxZ7JUBn3uw46aR7qd6V",
            "name": "The Grants",
            "duration_ms": 295000,
            "popularity": 68,
            "album": {
              "id": "5H0vAh6a25mSrye8xl5n3e",
              "name": "Did you know that there's a tunnel under Ocean Blvd",
              "images": [
                { "url": "https://i.scdn.co/image/ab67616d0000b273...", "height": 640, "width": 640 }
              ]
            },
            "artists": [
              { "id": "00FQZ4jHw0gmN79jR6jjGc", "name": "Lana Del Rey" }
            ]
          },
          "played_at": "2026-07-18T14:05:00Z",
          "context": {
            "type": "album",
            "uri": "spotify:album:5H0vAh6a25mSrye8xl5n3e"
          }
        }
      ],
      "next": "https://api.spotify.com/v1/me/player/recently-played?before=1784383500000&limit=20",
      "cursors": {
        "after": "1784383500000",
        "before": "1784383500000"
      }
    }
    ```

### Limitations & Edge Cases:
1.  **Limit of 50:** Spotify only returns the 50 most recently played tracks.
2.  **No Play-Count Info:** The endpoint does not tell us how many times a song was played, only the timestamp of that specific play.
3.  **Short Retention Window:** If a user listens to more than 50 songs on another device without opening this app, the intermediate songs are lost unless synced by a background server.
4.  **Short Track Exclusion:** Tracks must be played for at least 30 seconds to be registered in recently played.

---

## 3. Data Capture Strategy: Evaluation & Recommendation

To capture user listening history accurately, we evaluated three architectural patterns:

| Strategy | Architecture | Pros | Cons |
| :--- | :--- | :--- | :--- |
| **A: Client-Side Pull (Local SQL)** | App fetches `/recently-played` on launch/resume and persists records to a local database (SwiftData / CoreData). | • Easy to implement<br>• Fully serverless & stateless<br>• Keeps user data private | • Gaps in history if user plays >50 tracks between app opens |
| **B: Server-Side Polling (DynamoDB)** | Backend cron worker polls `/recently-played` every 45-60 mins for all active users, saving new plays to a database. | • Guarantees 100% history capture<br>• Enables custom dates & advanced analytics | • Higher AWS cost<br>• Requires secure storage of user refresh tokens in DB |
| **C: Client-Side BGAppRefresh** | App schedules iOS background tasks to poll in background. | • No server database needed | • Background execution is throttled & unreliable on iOS |

### Recommendation
We recommend **Strategy A (Client-Side Pull with SwiftData)** for the initial release to build a highly responsive and private feed. In the future, we can transition to **Strategy B (Server-Side Polling)** if users request complete web-based statistics. The design below targets Strategy A.

---

## 4. Swift Models & Architecture

### Play Record Model
We will define a new model to store specific playback occurrences.

```swift
// Types/IdentifiableTypes.swift
import Foundation

struct PlayRecord: Identifiable, Codable, Hashable {
    // Generate a unique ID using Spotify ID and the playback timestamp
    var id: String {
        return "\(spotifyId)-\(playedAt.timeIntervalSince1970)"
    }
    let spotifyId: String
    let name: String
    let artists: [Artist]
    let album: Album
    let playedAt: Date
    let durationMs: Int
    
    // Convert relative time string (e.g. "5m ago")
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: playedAt, relativeTo: Date())
    }
}
```

### Network Models
```swift
// Types/CodableTypes.swift
struct RecentlyPlayedResponse: Codable {
    let items: [PlayRecordResponse]
    let next: String?
    let cursors: CursorResponse?
}

struct PlayRecordResponse: Codable {
    let track: SongResponse
    let playedAt: String
    let context: ContextResponse?
    
    enum CodingKeys: String, CodingKey {
        case track
        case playedAt = "played_at"
        case context
    }
}

struct CursorResponse: Codable {
    let after: String?
    let before: String?
}

struct ContextResponse: Codable {
    let type: String
    let uri: String
}
```

---

## 5. UI Design & Layout Specs

### A. Recently Played Feed (`RecentlyPlayedView`)
*   **Placement:** 4th tab in the bottom `TabView` (SF Symbol: `clock.arrow.circlepath`).
*   **Visual Style:** Fits the **Technical Luxury** branding system:
    *   Background: `#0A0A0C` (Canvas).
    *   Containers: `.ultraThinMaterial` paired with `#FFFFFF0D` (Glass Surface) and `#FFFFFF33` (Glass Border).
    *   Motion: Linear spring settling (180 stiffness, 12 damping).
    *   Touch feedback: `llcThermalGlow()` on tap.
*   **Layout:**
    *   Header: "Recently Played" in Montserrat ExtraBold (34pt).
    *   List: Vertical scroll of tracks, ordered chronologically (newest first).
    *   Row Details:
        *   Artwork on the left.
        *   Title and Artist names in center.
        *   Relative played time (e.g., `"5m ago"`, `"2h ago"`) on the right in secondary label typography (`Open Sans`, `#98989F`, 13pt).

### B. Recency Indicator Badges
*   To connect the Recently Played feed with the Top Songs screen, we will render a subtle indicator on top songs if they were played recently.
*   **Design:** A small thermal corona dot (`#FF9500`) or a badge reading `"RECENT"` positioned next to the rank or track title.
*   **Rule:** A track is marked as "recent" if it appears in the recently played feed within the last 12 hours.

---

## 6. Implementation Milestones

1.  **Scope Verification:** Ensure that AuthManager requests the `user-read-recently-played` scope.
2.  **Model Extension:** Add `PlayRecord` and the response codables.
3.  **Data Controller updates:** Add `getRecentlyPlayed()` in `UserTopItems` to fetch and format records.
4.  **UI Construction:** Create `RecentlyPlayedView` and add it to `TabUIView`.
5.  **Recency Badge integration:** Update `GlassListRow` to optionally accept and display a `isRecent` state.
