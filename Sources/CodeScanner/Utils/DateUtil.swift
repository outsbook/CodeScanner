//
//  DateUtil.swift
//  CodeScanner
//
//  Created by Shahin Shams on 19/11/22.
//

import Foundation

class DateUtil{
    static func currentTimeInMillis() -> Int
    {
        let currentDate = Date()
        let since1970 = currentDate.timeIntervalSince1970
        return Int(since1970 * 1000)
    }
}
