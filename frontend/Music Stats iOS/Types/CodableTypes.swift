//
//  ResponseTypes.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/25/23.
//

struct TopSongsResponse: Codable, Hashable {
    var href: String
    var limit: Int
    var next: String?
    var offset: Int
    var previous: String?
    var total: Int
    var items: [SongResponse]
}

struct TopArtistsResponse: Codable, Hashable {
    var href: String
    var limit: Int
    var next: String?
    var offset: Int
    var previous: String?
    var total: Int
    var items: [ArtistResponse]
}

struct SongResponse: Codable, Hashable {
    var album: AlbumResponse
    var artists: [ArtistResponse]
    var durationMs: Int // in milliseconds
    var name: String
    var popularity: Int
    var id: String

    enum CodingKeys: String, CodingKey {
        case album
        case artists
        case durationMs = "duration_ms"
        case name
        case popularity
        case id
    }
}

struct ArtistResponse: Codable, Hashable {
    var images: [ImageResponse]?
    var name: String
    var popularity: Int?
    var id: String
    var genres: [String]?
}

struct AlbumResponse: Codable, Hashable {
    var images: [ImageResponse]
    var name: String
    var releaseDate: String
    var id: String
    var artists: [ArtistResponse]?
    var totalTracks: Int?
    var label: String?
    var popularity: Int?

    enum CodingKeys: String, CodingKey {
        case images
        case name
        case releaseDate = "release_date"
        case id
        case artists
        case totalTracks = "total_tracks"
        case label
        case popularity
    }
}

struct ImageResponse: Codable, Hashable {
    var url: String
    var height: Int?
    var width: Int?
}

struct UserProfileResponse: Codable, Hashable {
    var displayName: String?
    var email: String?
    var images: [ImageResponse]?
    var id: String

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case email
        case images
        case id
    }
}

struct AccessTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let scope: String
    let expiresIn: Int
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}
