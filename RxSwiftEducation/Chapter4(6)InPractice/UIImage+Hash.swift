//
//  UIImage+Hash.swift
//  RxSwiftEducation
//
//  Created by Дмитрий Федоринов on 20.03.2022.
//

// extensions
import UIKit
import CommonCrypto

extension UIImage {
    
    public func sha256() -> String{
        if let imageData = cgImage?.dataProvider?.data {
            return hexStringFromData(input: digest(input: imageData as NSData))
        }
        return ""
    }
    
    private func digest(input : NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }
    
    private  func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)
        
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }
        
        return hexString
    }
}
