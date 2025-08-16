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

// 두께 곡선 타입
enum SpineCurve {
 
    /*
     단순히 두께 = k × 페이지 수로 하면 비례(linear) 관계라서 1000쪽 책은 100쪽 책보다 무조건 10배 두껍게 나온다.
     그런데 실제 인쇄본 책은 종이 압축, 제본 구조 때문에 완전히 비례하지 않고, 체감상도 그렇게 10배 두껍게 느껴지진 않아.
     그래서 sqrt(제곱근), log(로그) 같은 곡선 함수를 쓰면 페이지 수가 많을수록 증가 속도가 줄어들어서 더 자연스러운 느낌이 나.
     
     linear: 📈 직선: 쭉 올라감
     두께가 페이지 수에 정비례. 단순하고 예측하기 쉬움.
     예) 100p → 14, 500p → 70, 1000p → 140 (계수 k=0.14일 때)

     sqrt: ⤴️ 살짝 꺾여 완만해짐
     두께가 제곱근에 비례. 페이지가 많아질수록 덜 두꺼워짐.
     예) 100p → 14, 500p → 31, 1000p → 44 (k=1.4일 때)
     → 500p와 1000p 차이가 크지 않음 → 상층부 “뭉뚝”해짐

     log: 🚶 거의 평평하게 가는 곡선
     두께가 로그(ln)에 비례. 증가가 가장 완만.
     예) 100p → 64, 500p → 124, 1000p → 193 (k=20일 때)
     → 초반엔 꽤 두꺼워지는데 뒤로 갈수록 “더 이상 안 두꺼워지는 느낌”
     */
    
    case linear(CGFloat)   // h = k * pages
    case sqrt(CGFloat)     // h = k * sqrt(pages)       (두꺼운 책 과장 줄임)
    case log(CGFloat)      // h = k * log1p(pages)      (가장 완만)
}

// 전역 설정(나중에 설정 화면에서 바꿔도 됨)
struct SpineConfig {
    //커브 설정
    static var curve: SpineCurve = .linear(0.12)     // 가장 현실적 표현. 계수값 조절하여 적당한 수준 찾기
    //static var curve: SpineCurve = .sqrt(2.0)      // 변화폭이 적음.....
    //static var curve: SpineCurve = .log(20)       // 전체적으로 너무 다 두껍게 표현됨 -> X
    
    static var minH: CGFloat = 12                 // 12 -> font 14일 때 안 잘리는 최소 높이 같음
    static var maxH: CGFloat? = nil               // 120 -> 너무 두꺼운 책 상한(원하면 nil)
    static var langMulKO: CGFloat = 1.0
    static var langMulForeign: CGFloat = 1.3     // 외국어 살짝 두껍게
    
    /*
     감 잡는 숫자 (현재 설정 기준, effort=1.0)
     30p: base 30×0.14=4.2 → minH 10 적용 → KO=10, 외서=10 (얇은 책은 동일)
     200p: 28 → KO=28, 외서=32.2
     500p: 70 → KO=70, 외서=80.5
     900p: 126 → KO=126, 외서=144.9（상한 없다면 꽤 길어짐）
     */
    
}

// effort: 난이도/체감가중치(미래 확장; 지금은 기본 1.0)
@inline(__always)
func spineHeight(pages: Int32, isKorean: Bool, effort: CGFloat = 1.0) -> CGFloat {
    let p = max(0, Int(pages))
    let base: CGFloat
    switch SpineConfig.curve {
    case .linear(let k): base = CGFloat(p) * k
    case .sqrt(let k):  base = sqrt(CGFloat(p)) * k
    case .log(let k):   base = log1p(CGFloat(p)) * k
    }
    let langMul = isKorean ? SpineConfig.langMulKO : SpineConfig.langMulForeign
    var h = max(SpineConfig.minH, base * langMul * effort)
    if let cap = SpineConfig.maxH { h = min(h, cap) }
    return h.rounded(.toNearestOrAwayFromZero) // 픽셀 스냅으로 가장자리 또렷
}

// 두께 계산: 페이지 수 + 언어 가중치
/*func spineHeight(pages: Int32, isKorean: Bool) -> CGFloat {
    let basePages = max(Int(pages), 30)        // 30p 이하는 너무 얇지 않게
    let k: CGFloat = 0.18                      // 1p당 높이(px) 계수 → 맛보기로 튜닝
    let langMul: CGFloat = isKorean ? 1.0 : 1.22 // 외국어 두껍게
    let minH: CGFloat = 18
    return max(minH, CGFloat(basePages) * k * langMul)
}
*/

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
