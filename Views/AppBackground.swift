//
//  AppBackground.swift
//  JjingBook
//
//  Created by Jeongah Seo on 9/20/25.
//

import SwiftUI

/// 배경 이미지가 있으면 사용, 없으면 그라데이션으로 대체
struct AppBackground: View {
    /// Assets 에 넣은 이미지 이름 (예: "StackBG")
    var imageName: String? = "StackBG"

    var body: some View {
        ZStack {
            if let name = imageName, UIImage(named: name) != nil {
                // 📷 배경 이미지
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    
                    .overlay(
                        ZStack {
                            // 흰색 레이어 → 전체를 연하게
                            Color.white.opacity(0.5)

                            // 비네팅 → 중앙은 살리고, 가장자리는 어둡게
                            RadialGradient(
                                colors: [.black.opacity(0.18), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 900
                            )
                            .blendMode(.multiply)
                        }
                        .ignoresSafeArea()
                    )
            } else {
                // 🎨 대체 그라데이션 (은은한 종이톤)
                LinearGradient(
                    colors: [Color(hex: "#FFF7EE"), Color(hex: "#F5E7D6")],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        }
        .allowsHitTesting(false) // 스크롤/제스처 방해 X
    }
}
