//
//  PrimaryButtonStyle.swift
//  datagigios
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
            .foregroundStyle(isEnabled ? .white : .secondary)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(isEnabled ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary), in: .rect(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
