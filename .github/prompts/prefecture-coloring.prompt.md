---
mode: agent
description: 訪問回数で色の深さが変わるシステムの実装
---

# PrefectureColor 実装仕様

## 目的
`Utilities/PrefectureColor.swift` を作成する。

## カラーマップ（visitCount → HEX）
| visitCount | HEX      | 意味       |
|-----------|---------|-----------|
| 0         | #DDDAD4 | 未訪問（グレー）|
| 1         | #C8C4F0 | 薄紫       |
| 2         | #9F97DD | 中紫       |
| 3, 4      | #7F77DD | 紫         |
| 5以上      | #534AB7 | 深紫       |

## 実装
```swift
extension Prefecture {
    func visitColor() -> Color {
        switch visitCount {
        case 0:    return Color(hex: "#DDDAD4")
        case 1:    return Color(hex: "#C8C4F0")
        case 2:    return Color(hex: "#9F97DD")
        case 3, 4: return Color(hex: "#7F77DD")
        default:   return Color(hex: "#534AB7")
        }
    }
}
```

## 例外
- 全国制覇後（全47県の visitCount >= 1）は全県を強制的に #534AB7 で表示
- isAllVisited: Bool を MapViewModel の computed property として定義する

## 完了条件
- force unwrap なし
- 全ケースが正しい Color を返す
