//
//  Theme.swift
//  JjingBook
//
//  Created by Jeongah Seo on 8/16/25.
//

import SwiftUI

extension Color {
    init(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch h.count {
        case 8: (a,r,g,b) = ((int>>24)&0xff, (int>>16)&0xff, (int>>8)&0xff, int&0xff)
        case 6: (a,r,g,b) = (255, (int>>16)&0xff, (int>>8)&0xff, int&0xff)
        default: (a,r,g,b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

enum Palette {
    // 한국어: 민트
    static let koTop   = Color(hex: "#BFE8DB")
    static let koBottom = Color(hex: "#9FD8C8")

    // 외국어: 노랑/밝은 오렌지
    static let enTop   = Color(hex: "#FFE3A2")
    static let enBottom = Color(hex: "#FFB26B")

    // 텍스트 대비가 약하면 이 스트로크/섀도우가 받쳐줌
    static let stroke = Color.white.opacity(0.28)
    static let shadow = Color.black.opacity(0.10)
    
    static let textDark = Color(hex: "#1B1C1E")   // 거의 블랙, 살짝 부드럽게
}

// 두께 계산: 페이지 수 + 언어 가중치
func spineHeight(pages: Int32, isKorean: Bool) -> CGFloat {
    let basePages = max(Int(pages), 30)        // 30p 이하는 너무 얇지 않게
    let k: CGFloat = 0.18                      // 1p당 높이(px) 계수 → 맛보기로 튜닝
    let langMul: CGFloat = isKorean ? 1.0 : 1.22 // 외국어 두껍게
    let minH: CGFloat = 18
    return max(minH, CGFloat(basePages) * k * langMul)
}

// 해시 기반 난수(책별 고정 오프셋/회전)
func stableJitter(from key: String) -> (rotation: Double, offsetX: CGFloat) {
    var hash = UInt64(1469598103934665603) // FNV-1a 64
    for u in key.unicodeScalars {
        hash ^= UInt64(u.value)
        hash &*= 1099511628211
    }
    // -3º ~ +3º,  -6 ~ +6 px
    let rot = Double(Int64(hash & 0x7) - 3)          // [-3, +3]
    let off = CGFloat(Int64((hash >> 3) & 0xF) - 8)  // [-8, +7] → 조금만
    return (rot, off)
}

// 책마다 "항상 같은" 가로 시작점 미세차이를 주기 위한 해시 기반 오프셋
func startOffsetX(from key: String, maxJitter: CGFloat = 24) -> CGFloat {
    var hash = UInt64(1469598103934665603) // FNV-1a
    for u in key.unicodeScalars { hash = (hash ^ UInt64(u.value)) &* 1099511628211 }
    let t = Double(hash % 10_000) / 10_000.0  // 0.0 ~ 1.0
    return CGFloat((t * 2.0 - 1.0)) * maxJitter // [-maxJitter, +maxJitter]
}
