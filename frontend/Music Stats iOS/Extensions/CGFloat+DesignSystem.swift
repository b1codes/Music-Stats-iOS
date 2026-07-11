// CGFloat+DesignSystem.swift
//
// Corner radius tokens for the "Technical Luxury" system specified in DESIGN.md.

import CoreGraphics

extension CGFloat {
    /// Small radius — smaller/nested elements (thumbnails, buttons): tighter than card radius.
    static let dsRoundedSM: CGFloat = 8

    /// Medium radius — cards, glass surfaces, and other primary containers.
    static let dsRoundedMD: CGFloat = 16
}
