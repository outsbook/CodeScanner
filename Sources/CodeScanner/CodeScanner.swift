//
//  CodeScanner.swift
//  CodeScanner
//
//  Created by Shahin Shams on 19/11/22.
//

import SwiftUI
import AVFoundation

public struct CodeScanner: View {
    public let sessionId: Int
    public let codeType: [AVMetadataObject.ObjectType]
    public var isMaskVisible: Bool
    public var isTorchEnable: Bool
    public var isSwitchCameraEnable: Bool
    public var isSwitchFocusEnable: Bool
    public var isVibrateOnSuccess: Bool
    public var onDone: (Result<CodeScanResult, CodeScanError>) -> Void
    
    @State private var mySessionId = 0
    @State private var isBackCamera = true
    @State private var isTorchOn = false
    @State private var isFocusOn = true
    
    public init(
        sessionId: Int,
        codeType: [AVMetadataObject.ObjectType],
        isMaskVisible: Bool = true,
        isTorchEnable: Bool = true,
        isSwitchCameraEnable: Bool = true,
        isSwitchFocusEnable: Bool = true,
        isVibrateOnSuccess: Bool = true,
        onDone: @escaping (Result<CodeScanResult, CodeScanError>) -> Void
    ){
        self.sessionId = sessionId
        self.codeType = codeType
        self.isMaskVisible = isMaskVisible
        self.isTorchEnable = isTorchEnable
        self.isSwitchCameraEnable = isSwitchCameraEnable
        self.isSwitchFocusEnable = isSwitchFocusEnable
        self.isVibrateOnSuccess = isVibrateOnSuccess
        self.onDone = onDone
    }
    
    public var body: some View {
        ZStack(alignment: .center){
            CodeScannerView(
                sessionId: sessionId,
                mySessionId: mySessionId,
                codeTypes: codeType,
                isBackCamera: isBackCamera,
                isTorchOn: isTorchOn,
                isFocusOn: isFocusOn
            ){ response in
                if case .success(_) = response {
                    isTorchOn = false
                }
                onDone(response)
            }
            
            VStack{
                HStack{
                    if isSwitchFocusEnable && DeviceUtil.isFocusSupport(isBackCamera: isBackCamera, isFocusOn: isFocusOn){
                        ButtonSwitchFocus(isFocusOn: isFocusOn){
                            switchFocus()
                        }
                    }
                    if isSwitchFocusEnable && DeviceUtil.isFocusSupport(isBackCamera: isBackCamera, isFocusOn: isFocusOn) && isTorchEnable && DeviceUtil.isHaveTorch(isBackCamera: isBackCamera){
                        Spacer()
                    }
                    if isTorchEnable && DeviceUtil.isHaveTorch(isBackCamera: isBackCamera){
                        ButtonSwitchTorch(isTorchOn: isTorchOn){
                            switchTorch()
                        }
                    }
                }
                Spacer()
                if isSwitchCameraEnable{
                    ButtonSwitchCamera{
                        switchCamera()
                    }
                }
            }
            .padding()
        }
    }
    
    private func switchCamera(){
        isTorchOn = false
        isFocusOn = true
        isBackCamera.toggle()
        mySessionId = DateUtil.currentTimeInMillis()
    }
    
    private func switchTorch(){
        isTorchOn.toggle()
    }
    
    private func switchFocus(){
        isFocusOn.toggle()
    }
    
    public static func getSessionId() -> Int{
        return DateUtil.currentTimeInMillis()
    }
}
