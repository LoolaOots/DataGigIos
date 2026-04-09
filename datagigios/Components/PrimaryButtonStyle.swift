//
//  PrimaryButtonStyle.swift
//  datagigios
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var isSuccess: Bool = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(background, in: .rect(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }

    private var foreground: AnyShapeStyle {
        if isSuccess { return AnyShapeStyle(.white) }
        return isEnabled ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary)
    }

    private var background: AnyShapeStyle {
        if isSuccess { return AnyShapeStyle(Color.green) }
        return isEnabled ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static var successPrimary: PrimaryButtonStyle { PrimaryButtonStyle(isSuccess: true) }
}
