//
//  DeviceUtil.swift
//  CodeScanner
//
//  Created by Shahin Shams on 19/11/22.
//

import Foundation
import AVFoundation

class DeviceUtil{
    static func getDevice(isBackCamera: Bool) -> AVCaptureDevice?{
        if isBackCamera{
            return AVCaptureDevice.default(for: .video)
        }
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes:[.builtInTrueDepthCamera, .builtInDualCamera, .builtInWideAngleCamera],
            mediaType: .video, position: .front
        )
        let devices = discoverySession.devices
        if devices.isEmpty{
            return AVCaptureDevice.default(for: .video)
        }
        return devices.first
    }
    
    static func isHaveTorch(isBackCamera: Bool) -> Bool{
        if let device = getDevice(isBackCamera: isBackCamera), device.hasTorch{
            return true
        }
        return false
    }
    
    static func isFocusSupport(isBackCamera: Bool, isFocusOn: Bool) -> Bool{
        let focusMode: AVCaptureDevice.FocusMode = isFocusOn ? .continuousAutoFocus : .autoFocus
        if let device = getDevice(isBackCamera: isBackCamera), device.isFocusModeSupported(focusMode){
            return true
        }
        return false
    }
}

