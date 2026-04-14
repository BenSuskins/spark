import SwiftUI
import UIKit

enum SparkColors {
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x29/255, green: 0x97/255, blue: 0xFF/255, alpha: 1) // #2997ff
            : UIColor(red: 0x00/255, green: 0x71/255, blue: 0xE3/255, alpha: 1) // #0071e3
    })

    static let primaryText = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? .white
            : UIColor(red: 0x1D/255, green: 0x1D/255, blue: 0x1F/255, alpha: 1) // #1d1d1f
    })

    static let secondaryText = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.56)
            : UIColor(white: 0, alpha: 0.56)
    })

    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? .black : .white
    })

    static let secondaryBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x1C/255, green: 0x1C/255, blue: 0x1E/255, alpha: 1) // #1c1c1e
            : UIColor(red: 0xF5/255, green: 0xF5/255, blue: 0xF7/255, alpha: 1) // #f5f5f7
    })

    static let cardBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x2A/255, green: 0x2A/255, blue: 0x2D/255, alpha: 1) // #2a2a2d
            : UIColor(red: 0xF5/255, green: 0xF5/255, blue: 0xF7/255, alpha: 1) // #f5f5f7
    })

    static let success = Color.green
    static let destructive = Color.red
}
