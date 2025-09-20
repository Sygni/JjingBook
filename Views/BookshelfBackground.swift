//
//  BookshelfBackground.swift
//  JjingBook
//
//  Created by Jeongah Seo on 9/20/25.
//

import SwiftUI

struct BookshelfBackground: View {
    // 선반 간격/높이 튜닝
    var shelfSpacing: CGFloat = 140
    var shelfHeight: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height

            ZStack {
                // 따뜻한 종이/원목 느낌의 그라데이션 배경
                LinearGradient(
                    colors: [
                        Color(hex: "#FFF7EE"),
                        Color(hex: "#F5E7D6")
                    ],
                    startPoint: .top, endPoint: .bottom
                )

                // 은은한 나무결(가로 선반들)
                ForEach(stride(from: shelfSpacing/2, through: h + shelfSpacing, by: shelfSpacing).map { $0 }, id: \.self) { y in
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#E7D3BE").opacity(0.9),
                                    Color(hex: "#DCC5AD").opacity(0.9)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: shelfHeight)
                        .offset(y: y)
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                }

                // 비네팅으로 시선 집중
                RadialGradient(
                    colors: [.black.opacity(0.10), .clear],
                    center: .center, startRadius: 0, endRadius: max(geo.size.width, h)
                )
                .blendMode(.multiply)
                .allowsHitTesting(false)
            }
            .ignoresSafeArea()
        }
    }
}
