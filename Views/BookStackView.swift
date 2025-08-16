//
//  BookStackView.swift
//  JjingBook
//
//  Created by Jeongah Seo on 8/16/25.
//

import SwiftUI

struct BookStackView: View {
    let book: Book
    
    private var bookHeight: CGFloat {
        let pages = CGFloat(book.pages)
        let minHeight: CGFloat = 20
        let maxHeight: CGFloat = 100
        let baseHeight = pages / 10 // 10페이지당 1포인트
        
        // 외국어 가중치 적용
        let multiplier = book.isKorean ? 1.0 : 1.5
        let finalHeight = baseHeight * multiplier
        
        return min(max(finalHeight, minHeight), maxHeight)
    }
    
    private var fontSize: CGFloat {
        // 책 높이에 비례한 폰트 크기
        let height = bookHeight
        return max(min(height * 0.3, 16), 10) // 최소 10, 최대 16
    }
    
    var body: some View {
        ZStack {
            // 책 배경
            RoundedRectangle(cornerRadius: 4)
                .fill(book.isKorean ? Color.blue.opacity(0.7) : Color.orange.opacity(0.7))
                .frame(height: bookHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.black.opacity(0.3), lineWidth: 1)
                )
            
            // 책 제목
            HStack {
                Text(book.title ?? "Untitled")
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                Spacer()
            }
        }
        .shadow(radius: 2, x: 0, y: 1)
    }
}
