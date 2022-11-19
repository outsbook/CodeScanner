//
//  CodeScanError.swift
//  CodeScanner
//
//  Created by Shahin Shams on 19/11/22.
//

import Foundation

public enum CodeScanError: Error{
    case badInputDevice
    case badMetadataOutput
    case initError(_ error: Error)
    case permissionDenied
}
