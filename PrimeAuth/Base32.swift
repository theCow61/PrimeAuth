//
//  Base32.swift
//  PrimeAuth
//
//  Created by Z Salti on 7/26/25.
//

import Foundation



struct Base32 {
    private static func charToByte(_ char: UInt8) -> UInt8? {
        // TODO: remove undercase check
        switch (char) {
        case 50...55: // numbers [2, 7]
            return char - 50 + 26
        case 65...90: // uppercase
            return char - 65
        case 97...122: // undercase
            return char - 97
        default:
            return nil
        }
    }
    
    static func decodeToData(_ base32: String) -> Data? {
        var dat: [UInt8] = []
        var byteCompletionCounter = 0
        for char in base32 {
            if char == "=" {
                break
            }
            guard let charVal = char.asciiValue else { return nil }
            guard let fiveBitPiece = charToByte(charVal) else { return nil }
            
            switch (byteCompletionCounter % 8) {
            case 0:
                dat.append(fiveBitPiece << 3)
            case 1:
                dat[dat.count - 1] = dat[dat.count - 1] | (fiveBitPiece << 2)
            case 2:
                dat[dat.count - 1] = dat[dat.count - 1] | (fiveBitPiece << 1)
            case 3:
                dat[dat.count - 1] = dat[dat.count - 1] | fiveBitPiece
            case 4:
                let highFiveBitPiece = fiveBitPiece & 0b11110
                dat[dat.count - 1] = dat[dat.count - 1] | (highFiveBitPiece >> 1)
                dat.append(fiveBitPiece << 7)
            case 5:
                let highFiveBitPiece = fiveBitPiece & 0b11100
                dat[dat.count - 1] = dat[dat.count - 1] | (highFiveBitPiece >> 2)
                dat.append(fiveBitPiece << 6)
            case 6:
                let highFiveBitPiece = fiveBitPiece & 0b11000
                dat[dat.count - 1] = dat[dat.count - 1] | (highFiveBitPiece >> 3)
                dat.append(fiveBitPiece << 5)
            default: // case 7
                let highFiveBitPiece = fiveBitPiece & 0b10000
                dat[dat.count - 1] = dat[dat.count - 1] | (highFiveBitPiece >> 4)
                dat.append(fiveBitPiece << 4)
            }
            byteCompletionCounter += 5
        }
        return Data(dat)
    }
}

