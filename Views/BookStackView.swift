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
        let h = spineHeight(pages: book.pages, isKorean: isKo)
        let colors = isKo ? [Palette.koTop, Palette.koBottom] : [Palette.enTop, Palette.enBottom]

        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Palette.stroke, lineWidth: 1)
                )

            // ✅ 제목은 진하게, 라이트/다크 모두 잘 보이도록 시스템 label 색상 사용
            Text(book.title ?? "")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Palette.textDark)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .shadow(color: .white.opacity(0.15), radius: 0, x: 0, y: 1) // (옵션) 밝은 배경에서 미세한 또렷함
        }
        .frame(height: h)
        //.padding(.horizontal, 6)  // ❌ 이거 제거 (부모에서 위치/폭 컨트롤)
        // ✅ 사이 간격 “없음”을 위해 .padding(.vertical) 제거
    }
}
