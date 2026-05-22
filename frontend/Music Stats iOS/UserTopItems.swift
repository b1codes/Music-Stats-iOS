//
//  UserTopItems.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 11/2/23.
//

import Foundation

@MainActor
class UserTopItems: ObservableObject {
    @Published var topSongsResponse: [String: [SongResponse]]
    @Published var topArtistsResponse: [String: [ArtistResponse]]
    @Published var topSongsList: [String: [Song]]
    @Published var topArtistsList: [String: [Artist]]
    @Published var topAlbumsList: [String: [Album]]
    @Published var userProfile: UserProfile?
    @Published var fetchState: ViewState = .loading
    var accessToken: String
    var tokenType: String

    init() {
        self.topSongsResponse = [:]
        self.topArtistsResponse = [:]
        self.topSongsList = [:]
        self.topArtistsList = [:]
        self.topAlbumsList = [:]
        self.userProfile = nil
        self.accessToken = ""
        self.tokenType = ""
    }

    func getUserProfile() async {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/v1/me"

        guard let url = components.url else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Authorization": "\(tokenType) \(accessToken)"]

        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return }

        if let responseObject = try? JSONDecoder().decode(UserProfileResponse.self, from: data) {
            userProfile = UserProfile(
                id: responseObject.id,
                displayName: responseObject.displayName,
                email: responseObject.email,
                images: responseObject.images
            )
        }
    }

    func getTopSongs() async throws {
        async let short = getSongsForTimeRange(range: "short_term", offset: 0)
        async let medium = getSongsForTimeRange(range: "medium_term", offset: 0)
        async let long = getSongsForTimeRange(range: "long_term", offset: 0)
        let (shortResponse, mediumResponse, longResponse) = try await (short, medium, long)

        for (key, response) in zip(["short", "medium", "long"], [shortResponse, mediumResponse, longResponse]) {
            topSongsResponse[key] = response.items
            topSongsList[key] = response.items.enumerated().map { (index, songResponse) in
                let album = Album(
                    id: songResponse.album.id,
                    spotifyId: songResponse.album.id,
                    rank: nil,
                    images: songResponse.album.images,
                    name: songResponse.album.name,
                    artists: songResponse.artists.map {
                        Artist(id: "album-artist-\($0.id)", spotifyId: $0.id, name: $0.name)
                    },
                    releaseDate: songResponse.album.releaseDate,
                    totalTracks: songResponse.album.totalTracks
                )
                let rank = index + 1
                let artists = songResponse.artists.map {
                    Artist(id: "song-artist-\($0.id)", spotifyId: $0.id, name: $0.name)
                }
                return Song(
                    id: "\(key)-\(rank)-\(songResponse.id)",
                    spotifyId: songResponse.id,
                    rank: rank,
                    album: album,
                    artists: artists,
                    durationMs: songResponse.durationMs,
                    name: songResponse.name,
                    popularity: songResponse.popularity
                )
            }
        }
        calculateTopAlbums()
    }

    func getTopArtists() async throws {
        async let short = getArtistsForTimeRange(range: "short_term", offset: 0)
        async let medium = getArtistsForTimeRange(range: "medium_term", offset: 0)
        async let long = getArtistsForTimeRange(range: "long_term", offset: 0)
        let (shortResponse, mediumResponse, longResponse) = try await (short, medium, long)

        for (key, response) in zip(["short", "medium", "long"], [shortResponse, mediumResponse, longResponse]) {
            topArtistsResponse[key] = response.items
            topArtistsList[key] = response.items.enumerated().map { (index, artistResponse) in
                let rank = index + 1
                return Artist(
                    id: "\(key)-\(rank)-\(artistResponse.id)",
                    spotifyId: artistResponse.id,
                    rank: rank,
                    images: artistResponse.images,
                    name: artistResponse.name,
                    popularity: artistResponse.popularity,
                    genres: artistResponse.genres
                )
            }
        }
    }

    func fetchAll() async {
        do {
            async let songs: Void = getTopSongs()
            async let artists: Void = getTopArtists()
            try await songs
            try await artists
            fetchState = .content
        } catch {
            fetchState = .error
        }
    }

    func retry() {
        fetchState = .loading
        topSongsResponse = [:]
        topArtistsResponse = [:]
        topSongsList = [:]
        topArtistsList = [:]
        topAlbumsList = [:]
        Task {
            await getUserProfile()
            await fetchAll()
        }
    }

    func calculateTopAlbums() {
        let keys = ["short", "medium", "long"]
        for key in keys {
            guard let songs = topSongsList[key] else {
                self.topAlbumsList[key] = []
                continue
            }

            var groupToSongs: [String: [Song]] = [:]
            for song in songs {
                let normalizedName = normalizeAlbumName(song.album.name)
                let primaryArtistId = song.artists.first?.spotifyId ?? "unknown"
                let groupKey = "\(normalizedName)||\(primaryArtistId)"
                groupToSongs[groupKey, default: []].append(song)
            }

            let filteredGroups = groupToSongs.values.filter { $0.count > 1 }

            let sortedGroups = filteredGroups.sorted { songs1, songs2 in
                let score1 = songs1.reduce(0) { $0 + (51 - ($1.rank ?? 51)) }
                let score2 = songs2.reduce(0) { $0 + (51 - ($1.rank ?? 51)) }
                return score1 > score2
            }

            self.topAlbumsList[key] = sortedGroups.enumerated().map { index, songs in
                let representative = songs.min(by: { $0.album.name.count < $1.album.name.count })!
                return Album(
                    id: "\(key)-\(index + 1)-\(representative.album.spotifyId ?? representative.album.id)",
                    spotifyId: representative.album.spotifyId,
                    rank: index + 1,
                    images: representative.album.images,
                    name: representative.album.name,
                    artists: representative.artists,
                    releaseDate: representative.album.releaseDate,
                    totalTracks: representative.album.totalTracks,
                    songCount: songs.count,
                    contributingSongs: songs
                )
            }
        }
    }

    func getSongsForTimeRange(range: String, offset: Int) async throws -> TopSongsResponse {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/v1/me/top/tracks"
        components.queryItems = [
            URLQueryItem(name: "time_range", value: range),
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "offset", value: String(offset))
        ]

        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Authorization": "\(tokenType) \(accessToken)"]

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw NetworkError.badStatusCode(code)
        }

        return try JSONDecoder().decode(TopSongsResponse.self, from: data)
    }

    func getArtistsForTimeRange(range: String, offset: Int) async throws -> TopArtistsResponse {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/v1/me/top/artists"
        components.queryItems = [
            URLQueryItem(name: "time_range", value: range),
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "offset", value: String(offset))
        ]

        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Authorization": "\(tokenType) \(accessToken)"]

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw NetworkError.badStatusCode(code)
        }

        return try JSONDecoder().decode(TopArtistsResponse.self, from: data)
    }

    func reset() {
        topSongsResponse = [:]
        topArtistsResponse = [:]
        topSongsList = [:]
        topArtistsList = [:]
        topAlbumsList = [:]
        userProfile = nil
        accessToken = ""
        tokenType = ""
        fetchState = .loading
    }
}

// MARK: - Individual Item Fetching
extension UserTopItems {
    func getTrack(id: String) async throws -> SongResponse {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/v1/tracks/\(id)"

        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Authorization": "\(tokenType) \(accessToken)"]

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw NetworkError.badStatusCode(code)
        }

        return try JSONDecoder().decode(SongResponse.self, from: data)
    }

    func getArtist(id: String) async throws -> ArtistResponse {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/v1/artists/\(id)"

        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Authorization": "\(tokenType) \(accessToken)"]

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw NetworkError.badStatusCode(code)
        }

        return try JSONDecoder().decode(ArtistResponse.self, from: data)
    }

    func getAlbum(id: String) async throws -> AlbumResponse {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.spotify.com"
        components.path = "/v1/albums/\(id)"

        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Authorization": "\(tokenType) \(accessToken)"]

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw NetworkError.badStatusCode(code)
        }

        return try JSONDecoder().decode(AlbumResponse.self, from: data)
    }
}

// MARK: - Album Name Normalization

extension UserTopItems {
    private func normalizeAlbumName(_ name: String) -> String {
        let pattern = #"\s*[(\[][^)\]]*?(?:deluxe|edition|remaster(?:ed)?|bonus|special|anniversary|expanded|platinum|collector|3am)[^)\]]*[)\]]"#
        return name
            .replacingOccurrences(of: pattern, with: "", options: [.regularExpression, .caseInsensitive])
            .trimmingCharacters(in: .whitespaces)
            .lowercased()
    }
}
