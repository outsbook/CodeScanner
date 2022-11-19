//
//  ButtonSwitchCamera.swift
//  CodeScanner
//
//  Created by Shahin Shams on 19/11/22.
//

import SwiftUI

struct ButtonSwitchCamera: View {
    var onAction: () -> Void
    var body: some View {
        Button(action: {
            onAction()
        }){
            Image(uiImage: UIImage(named: "SwitchCamera", in: .module, with: nil)!)
                .renderingMode(.template)
                .resizable()
                .foregroundColor(.white)
                .padding(8)
                .frame(width: 38, height: 38)
                .background(Color.black.opacity(0.5))
                .cornerRadius(19)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
