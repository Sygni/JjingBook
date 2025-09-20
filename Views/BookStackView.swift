//
//  BookStackView.swift
//  JjingBook
//
//  Created by Jeongah Seo on 8/16/25.
//

import SwiftUI

// NaN/Inf 방지용 안전 클램프 유틸
@inline(__always)
private func safeCGFloat(_ x: CGFloat, min minV: CGFloat = 0,
                         max maxV: CGFloat = .greatestFiniteMagnitude) -> CGFloat {
    guard x.isFinite else { return minV }
    if x.isNaN { return minV }
    return Swift.max(minV, Swift.min(x, maxV))
}

struct BookStackView: View {
    let book: Book
    var tone: CGFloat = 1.0   // 🔹 1.0=원본, 0.92=살짝 어둡게 등

    var body: some View {
        let isKo = book.isKorean
        
        // pages 안전 가드(0/음수 → 최소 1)
        let pagesInt = Int(book.pages)
        let pagesSafe = max(1, pagesInt)

        // spineHeight 반환값도 추가 가드(최소/최대 높이 범위)
        let hRaw = spineHeight(pages: Int32(pagesSafe), isKorean: isKo, effort: 1.0)
        //let h = spineHeight(pages: book.pages, isKorean: book.isKorean, effort: 1.0)
        //let h = safeCGFloat(hRaw, min: 16, max: 140)   // 최소/최대 높이는 프로젝트에 맞게
        let minH = SpineConfig.minH
        let maxH = SpineConfig.maxH ?? .greatestFiniteMagnitude
        let h = safeCGFloat(hRaw, min: minH, max: maxH)

        //let colors = isKo ? [Palette.koTop, Palette.koBottom] : [Palette.enTop, Palette.enBottom]
        let baseTop    = isKo ? Palette.koTop    : Palette.enTop
        let baseBottom = isKo ? Palette.koBottom : Palette.enBottom
        let colors = [
            baseTop.adjusted(brightness: tone, saturation: 1.0),
            baseBottom.adjusted(brightness: tone, saturation: 1.0)
        ]
        
        // 얇은 책은 폰트를 줄여서 높이 안에 맞춘다
        let baseFont: CGFloat = 13
        let minFont: CGFloat = 13   // 11 -> 13으로 했는데 이렇게 해도 책 안 겹치고 해결됨..
        let safeInset: CGFloat = 6 // 위/아래 여유
        
        // fontSize도 음수/NaN 차단
        let fontCandidate = min(baseFont, h - safeInset)
        let fontSize = safeCGFloat(fontCandidate, min: minFont, max: baseFont)
        //let fontSize = max(minFont, min(baseFont, h - safeInset))
        
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    // 책등 림(스트로크)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Palette.stroke, lineWidth: 1)
                )
                //.shadow(color: Palette.shadow, radius: 4, x: 0, y: 2)     //넣어봤지만 아무 티가 안 남...
            
                // 상하 하이라이트/섀도우로 책등 입체감
                .overlay(
                    VStack(spacing: 0) {
                        // 위 하이라이트
                        LinearGradient(colors: [Color.white.opacity(0.24), .clear],
                                       startPoint: .top, endPoint: .bottom)
                            .frame(height: 6)
                        Spacer(minLength: 0)
                        // 아래 섀도우
                        LinearGradient(colors: [.black.opacity(0.12), .clear],
                                       startPoint: .bottom, endPoint: .top)
                            .frame(height: 6)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                )

                // 가운데 미세한 “제본선” 하이라이트 (두꺼운 책에서만 살짝)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(
                            LinearGradient(colors: [.white.opacity(h > 24 ? 0.08 : 0.0),
                                                    .clear],
                                           startPoint: .top, endPoint: .bottom),
                            lineWidth: 1.0
                        )
                )

            // 제목은 진하게, 라이트/다크 모두 잘 보이도록 시스템 label 색상 사용
            Text(book.title ?? "")
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(Palette.textDark)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 12)
                .shadow(color: .white.opacity(0.12), radius: 0, x: 0, y: 1) // (옵션) 밝은 배경에서 미세한 또렷함
        }
        .frame(height: h, alignment: .center)
        .clipped() // 내용이 높이 밖으로 새지 않게
        .contentShape(Rectangle())
        .shadow(color: .black.opacity(0.07), radius: 3, x: 0, y: 2)
        //.padding(.horizontal, 6)  // ❌ 이거 제거 (부모에서 위치/폭 컨트롤)
        // 사이 간격 “없음”을 위해 .padding(.vertical) 제거
        
        // 책 외곽선 강조 (아주 옅게)
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 0.8)
        )
        
    }
}
