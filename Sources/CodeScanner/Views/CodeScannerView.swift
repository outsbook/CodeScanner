//
//  CodeScannerView.swift
//  CodeScanner
//
//  Created by Shahin Shams on 19/11/22.
//

import Foundation
import AVFoundation
import SwiftUI
import UIKit

struct CodeScannerView: UIViewControllerRepresentable {
    let sessionId: Int
    let mySessionId: Int
    let codeType: [AVMetadataObject.ObjectType]
    var isBackCamera: Bool
    var isMaskVisible: Bool
    var isTorchOn: Bool
    var isFocusOn: Bool
    var isVibrateOnSuccess: Bool
    var onDone: (Result<CodeScanResult, CodeScanError>) -> Void

    init(
        sessionId: Int,
        mySessionId: Int,
        codeTypes: [AVMetadataObject.ObjectType],
        isBackCamera: Bool = true,
        isMaskVisible: Bool = true,
        isTorchOn: Bool = false,
        isFocusOn: Bool = true,
        isVibrateOnSuccess: Bool = true,
        onDone: @escaping (Result<CodeScanResult, CodeScanError>) -> Void
    ) {
        self.sessionId = sessionId
        self.mySessionId = mySessionId
        self.codeType = codeTypes
        self.isBackCamera = isBackCamera
        self.isMaskVisible = isMaskVisible
        self.isTorchOn = isTorchOn
        self.isFocusOn = isFocusOn
        self.isVibrateOnSuccess = isVibrateOnSuccess
        self.onDone = onDone
    }

    func makeUIViewController(context: Context) -> CodeScannerViewController {
        return CodeScannerViewController(parentView: self)
    }

    func updateUIViewController(_ viewController: CodeScannerViewController, context: Context) {
        viewController.parentView = self
        viewController.updateViewController(
            sessionId: sessionId,
            mySessionId: mySessionId
        )
    }
}
