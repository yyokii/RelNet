//
//  FlowLayout.swift
//  RelNet
//
//  Created by Higashihara Yoki on 2023/10/07.
//

import SwiftUI

/*
 source https://developer.apple.com/documentation/swiftui/food_truck_building_a_swiftui_multiplatform_app/
 */
struct FlowLayout: Layout {
    var alignment: Alignment = .center
    var spacing: CGFloat?

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.bounds
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        for row in result.rows {
            let rowXOffset = (bounds.width - row.frame.width) * alignment.horizontal.percent
            for index in row.range {
                let xPos = bounds.minX + row.frame.minX + rowXOffset + row.xOffsets[index - row.range.lowerBound]

                let rowYAlignment = (row.frame.height - subviews[index].sizeThatFits(.unspecified).height) * alignment.vertical.percent
                let yPos = row.frame.minY + rowYAlignment + bounds.minY

                subviews[index].place(at: CGPoint(x: xPos, y: yPos), anchor: .topLeading, proposal: .unspecified)
            }
        }
    }

    struct FlowResult {
        var bounds = CGSize.zero
        // 行ごとのサブビューの配置情報
        var rows = [Row]()

        struct Row {
            var range: Range<Int>
            var xOffsets: [Double]
            var frame: CGRect
        }

        init(in maxPossibleWidth: Double, subviews: Subviews, spacing: CGFloat?) {
            var itemsInRow = 0
            var remainingWidth = maxPossibleWidth.isFinite ? maxPossibleWidth : .greatestFiniteMagnitude
            var rowMinY = 0.0
            var rowHeight = 0.0
            // 各サブビューのx座標のオフセット
            var xOffsets: [Double] = []
            for (index, subview) in zip(subviews.indices, subviews) {
                let idealSize = subview.sizeThatFits(.unspecified)

                // 現在の行にサブビューを追加するか、新しい行を開始するかを判断
                if index != 0 && widthInRow(index: index, idealWidth: idealSize.width) > remainingWidth {
                    // 現在の行には追加せずに新しい行を開始
                    let rowLastIndex = index - 1
                    finalizeRow(index: max(rowLastIndex, 0), idealSize: idealSize)
                }
                addToRow(index: index, idealSize: idealSize)

                if index == subviews.count - 1 {
                    // Finish this row; it's either full or we're on the last view anyway.
                    finalizeRow(index: index, idealSize: idealSize)
                }
            }

            func spacingBefore(index: Int) -> Double {
                guard itemsInRow > 0 else { return 0 }
                return spacing ?? subviews[index - 1].spacing.distance(to: subviews[index].spacing, along: .horizontal)
            }

            func widthInRow(index: Int, idealWidth: Double) -> Double {
                idealWidth + spacingBefore(index: index)
            }

            func addToRow(index: Int, idealSize: CGSize) {
                let width = widthInRow(index: index, idealWidth: idealSize.width)

                xOffsets.append(maxPossibleWidth - remainingWidth + spacingBefore(index: index))
                // Viewのサイズとスペースを割り当てる
                remainingWidth -= width
                // 高さは行の中で一番大きいものに合わせる
                rowHeight = max(rowHeight, idealSize.height)

                itemsInRow += 1
            }

            /// ここまでのデータで新しいRowを作成し、新しい行を開始するためにプロパティを初期化
            func finalizeRow(index: Int, idealSize: CGSize) {
                let rowWidth = maxPossibleWidth - remainingWidth
                rows.append(
                    Row(
                        range: index - max(itemsInRow - 1, 0)..<index + 1,
                        xOffsets: xOffsets,
                        frame: CGRect(x: 0, y: rowMinY, width: rowWidth, height: rowHeight)
                    )
                )
                bounds.width = max(bounds.width, rowWidth)
                let ySpacing = spacing ?? ViewSpacing().distance(to: ViewSpacing(), along: .vertical)
                bounds.height += rowHeight + (rows.count > 1 ? ySpacing : 0)
                rowMinY += rowHeight + ySpacing
                itemsInRow = 0
                rowHeight = 0
                xOffsets.removeAll()
                remainingWidth = maxPossibleWidth
            }
        }
    }
}

private extension HorizontalAlignment {
    var percent: Double {
        switch self {
        case .leading: return 0
        case .trailing: return 1
        default: return 0.5
        }
    }
}

private extension VerticalAlignment {
    var percent: Double {
        switch self {
        case .top: return 0
        case .bottom: return 1
        default: return 0.5
        }
    }
}
