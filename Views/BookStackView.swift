//
//  BookStackView.swift
//  JjingBook
//
//  Created by Jeongah Seo on 8/16/25.
//

import SwiftUI

struct BookStackView: View {
    let book: Book

    var body: some View {
        let isKo = book.isKorean
        let h = spineHeight(pages: book.pages, isKorean: book.isKorean, effort: 1.0)
        let colors = isKo ? [Palette.koTop, Palette.koBottom] : [Palette.enTop, Palette.enBottom]

        // 얇은 책은 폰트를 줄여서 높이 안에 맞춘다
        let baseFont: CGFloat = 13
        let minFont: CGFloat = 13   // 11 -> 13으로 했는데 이렇게 해도 책 안 겹치고 해결됨..
        let safeInset: CGFloat = 6 // 위/아래 여유
        let fontSize = max(minFont, min(baseFont, h - safeInset))
        
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Palette.stroke, lineWidth: 1)
                )

            // ✅ 제목은 진하게, 라이트/다크 모두 잘 보이도록 시스템 label 색상 사용
            Text(book.title ?? "")
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(Palette.textDark)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .shadow(color: .white.opacity(0.15), radius: 0, x: 0, y: 1) // (옵션) 밝은 배경에서 미세한 또렷함
        }
        .frame(height: h, alignment: .center)
        .clipped() // ✅ 내용이 높이 밖으로 새지 않게
        .contentShape(Rectangle())
        //.padding(.horizontal, 6)  // ❌ 이거 제거 (부모에서 위치/폭 컨트롤)
        // ✅ 사이 간격 “없음”을 위해 .padding(.vertical) 제거
    }
}
