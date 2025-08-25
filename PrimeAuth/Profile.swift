//
//  Profile.swift
//  PrimeAuth
//
//  Created by Z Salti on 7/21/25.
//

import Foundation
import SwiftData
import CryptoKit

struct KeyPair {
    fileprivate var publicKey: SecKey
    fileprivate var privateKey: SecKey
    
    init(publicKey: SecKey, privateKey: SecKey) {
        self.publicKey = publicKey
        self.privateKey = privateKey
    }
    
}

var GKeys: KeyPair? = nil


@Model
class Profile {
    var name: String
    private var encryptedSecret: Data?
    var accessCount: Int
    @Transient private static let timeStep: Int = 30 // Don't actually save this in the db

    init?(name: String, secret: String, accessCount: Int) {
        self.accessCount = accessCount
        self.name = name
        guard let cipher = encryptBase32Secret(secret: secret, pubkey: GKeys.unsafelyUnwrapped.publicKey) else { return nil }
        self.encryptedSecret = cipher
    }
    
    func get2Auth6DigitCode() -> String? {
        let secret = decryptCipheredSecret(cipher: self.encryptedSecret.unsafelyUnwrapped, privkey: GKeys.unsafelyUnwrapped.privateKey)
        let timeInput = Int(Date().timeIntervalSince1970) / Profile.timeStep
        let timeInputData: Data = withUnsafeBytes(of: timeInput.bigEndian) { Data($0) }
        let symKey = SymmetricKey(data: secret!)
            
        let hmac = HMAC<Insecure.SHA1>.authenticationCode(for: timeInputData, using: symKey)
        return hmac.withUnsafeBytes { rawBuf in // don't do a copy
            let offset = Int(rawBuf[19] & 0x0f)
            //let pieceBase = rawBuf.baseAddress!.advanced(by: offset)
            let piece = UInt32(bigEndian: rawBuf.loadUnaligned(fromByteOffset: offset, as: UInt32.self)) & 0x7fffffff
            //let piece: UInt32 = (UInt32(rawBuf[offset] & 0x7f) << 24) | (UInt32(rawBuf[offset + 1]) << 16) | (UInt32(rawBuf[offset + 2]) << 8) | UInt32(rawBuf[offset + 3])
            let code = piece % 1000000
            return String(format: "%06d", code)
        }
    }
    
    private func encryptBase32Secret(secret: String, pubkey: SecKey) -> Data? {
        //guard let decodedSecretPlain = Data(base64Encoded: secret) else { return nil }
        guard let decodedSecretPlain = Base32.decodeToData(secret) else { return nil }
        //debugPrint(decodedSecretPlain.count)
        //debugPrint(String(bytes: decodedSecretPlain, encoding: .utf8)!)
        var encError: Unmanaged<CFError>?
        let cipherData = SecKeyCreateEncryptedData(pubkey, .eciesEncryptionCofactorX963SHA256AESGCM, decodedSecretPlain as CFData, &encError) as Data?
        return cipherData
    }
    
    private func decryptCipheredSecret(cipher: Data, privkey: SecKey) -> Data? {
        var decError: Unmanaged<CFError>?
        let clearData = SecKeyCreateDecryptedData(privkey, .eciesEncryptionCofactorX963SHA256AESGCM, cipher as CFData, &decError) as Data?
        return clearData
    }
}
