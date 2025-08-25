//
//  PrimeAuthApp.swift
//  PrimeAuth
//
//  Created by Z Salti on 7/19/25.
//

import SwiftUI
import SwiftData
import LocalAuthentication
import ScreenCaptureKit
import CoreImage

//var GpublicKey: SecKey? = nil
//var GprivateKey: SecKey? = nil

let bundleIdentifier = "com.zanes.PrimeAuth"

@main
struct PrimeAuthApp: App {
    
    var body: some Scene {
        /*WindowGroup {
            ContentView()
        }*/
//        MenuBarExtra() {
//            ContentView().modelContainer(for: Profile.self)
//        }
//        label: {
//            Label("PrimeAuth", systemImage: "person.badge.key.fill")
//        }
        MenuBarExtra("PrimeAuth", systemImage: "person.badge.key.fill") {
            ContentView().modelContainer(for: Profile.self)
        }.menuBarExtraStyle(.window)
    }
    
    init() {
        GKeysInitialization()
//        testingAround()
    }
    
    private func GKeysInitialization() {
        let context = LAContext()
        context.localizedReason = "Doot"

        let privKey = getFromKeychain(lacontext: context)
        if privKey == nil {
            debugPrint("No key found. Lets make one.")
            guard let newPrivateKey = createKeyKeychain(lacontext: context) else {
                fatalError("Failed to make new private key")
            }
            guard let publicKey = SecKeyCopyPublicKey(newPrivateKey) else {
                fatalError("Failed to make new public key")
            }
            debugPrint(publicKey)
            GKeys = KeyPair(publicKey: publicKey, privateKey: newPrivateKey)
        } else {
            /*let getquery: [String: Any] = [
                kSecClass as String: kSecClassKey,
                kSecAttrApplicationTag as String: "com.zanes.PrimeAuth",
                kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                kSecReturnRef as String: true
            ]
            SecItemDelete(getquery as CFDictionary)*/
            guard let publicKey = SecKeyCopyPublicKey(privKey!) else {
                fatalError("Failed to get public key associated with private key")
            }
            debugPrint(publicKey)
            GKeys = KeyPair(publicKey: publicKey, privateKey: privKey!)
            //GpublicKey = publicKey
            //GprivateKey = privKey.unsafelyUnwrapped
            /*var encError: Unmanaged<CFError>?
            let plainText = "plain".data(using: .utf8)! as CFData
            let cipherText = SecKeyCreateEncryptedData(publicKey, .eciesEncryptionCofactorX963SHA256AESGCM, plainText, &encError) as Data?
            debugPrint((cipherText?.base64EncodedString()).unsafelyUnwrapped)
            
            
            var decError: Unmanaged<CFError>?
            let clearText = SecKeyCreateDecryptedData(privKey.unsafelyUnwrapped, .eciesEncryptionCofactorX963SHA256AESGCM, cipherText.unsafelyUnwrapped as CFData, &decError) as Data?
            debugPrint(String(data: clearText.unsafelyUnwrapped, encoding: .utf8).unsafelyUnwrapped)*/
        }
    }
    
    private func getFromKeychain(lacontext: LAContext) -> SecKey? {
        /*let getquery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: "com.zanes.PrimeAuth",
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecUseAuthenticationContext as String: context,
            kSecReturnRef as String: true
        ]*/
        
        let getquery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: bundleIdentifier,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            //kSecUseAuthenticationContext as String: lacontext,
            kSecReturnRef as String: true
        ]

        var item: CFTypeRef?
        
        let status = SecItemCopyMatching(getquery as CFDictionary, &item)
        return status == errSecSuccess ? (item as! SecKey) : nil
    }
    
    private func createKeyKeychain(lacontext: LAContext) -> SecKey? {
        guard let access = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, [.privateKeyUsage, .biometryAny], nil) else { return nil }
        let attributes: NSDictionary = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
            //kSecUseAuthenticationContext: lacontext,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: true,
                kSecAttrApplicationTag: bundleIdentifier,
                kSecAttrAccessControl: access
            ]
        ]
        var error: Unmanaged<CFError>? = nil
        /*guard let privateKey = SecKeyCreateRandomKey(attributes, &error) else {
            //throw error!.takeRetainedValue() as Error
            return nil
        }*/
        
        //let status = SecItemAdd(attributes, nil)
        //guard status == errSecSuccess else { return nil }
        
        let privateKey = SecKeyCreateRandomKey(attributes, &error)
        //return getFromKeychain(lacontext: lacontext)
        return error == nil ? privateKey : nil

    }

    private func testingAround() {
        debugPrint("test")
        
        let context = LAContext()
        context.localizedReason = "Doot"

        let privKey = getFromKeychain(lacontext: context)
        if privKey == nil {
            debugPrint("No key found. Lets make one.")
            let newPrivateKey = createKeyKeychain(lacontext: context)
            if newPrivateKey == nil {
                debugPrint("Failed to make new key")
            } else {
                let publicKey = SecKeyCopyPublicKey(newPrivateKey.unsafelyUnwrapped)
                if publicKey == nil {
                    debugPrint("Failed to make public key")
                } else {
                    debugPrint(publicKey.unsafelyUnwrapped)
                    GKeys = KeyPair(publicKey: publicKey.unsafelyUnwrapped, privateKey: newPrivateKey.unsafelyUnwrapped)
                    //GpublicKey = publicKey.unsafelyUnwrapped
                    //GprivateKey = newPrivateKey.unsafelyUnwrapped
                }
            }
        } else {
            /*let getquery: [String: Any] = [
                kSecClass as String: kSecClassKey,
                kSecAttrApplicationTag as String: "com.zanes.PrimeAuth",
                kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                kSecReturnRef as String: true
            ]
            SecItemDelete(getquery as CFDictionary)*/
            let publicKey = SecKeyCopyPublicKey(privKey.unsafelyUnwrapped).unsafelyUnwrapped
            debugPrint(publicKey)
            GKeys = KeyPair(publicKey: publicKey, privateKey: privKey.unsafelyUnwrapped)
            //GpublicKey = publicKey
            //GprivateKey = privKey.unsafelyUnwrapped
            /*var encError: Unmanaged<CFError>?
            let plainText = "plain".data(using: .utf8)! as CFData
            let cipherText = SecKeyCreateEncryptedData(publicKey, .eciesEncryptionCofactorX963SHA256AESGCM, plainText, &encError) as Data?
            debugPrint((cipherText?.base64EncodedString()).unsafelyUnwrapped)
            
            
            var decError: Unmanaged<CFError>?
            let clearText = SecKeyCreateDecryptedData(privKey.unsafelyUnwrapped, .eciesEncryptionCofactorX963SHA256AESGCM, cipherText.unsafelyUnwrapped as CFData, &decError) as Data?
            debugPrint(String(data: clearText.unsafelyUnwrapped, encoding: .utf8).unsafelyUnwrapped)*/
        }
        
        /*let tempDirectory = NSTemporaryDirectory()
        debugPrint(tempDirectory)
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        task.arguments = ["-i", tempDirectory.appending("cap.png")]
        do { try task.run() } catch {
            
        }*/
        
        //SCShareableContent
        // |
        //SCContentFilter       SCStreamConfiguration       ^Screenshot
        // |                            |                   |
        //                  SCScreenshotManager captureScreenshot <- object not needed
        
        
        
        //let contentFilter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        //let picker = SCContentSharingPicker.shared
        //let bruh = Tosst()
        //picker.add(bruh)
        //picker.isActive = true
        //picker.present()
        /*Task {
            //picker.add
            
            let wasd: SCShareableContent = try! await SCShareableContent.current
            debugPrint(wasd.displays)
            debugPrint(wasd.windows)
            let contentFilter = SCContentFilter(display: wasd.displays[1], excludingApplications: [], exceptingWindows: [])
            let conf = SCStreamConfiguration()
            conf.showsCursor = false
        }*/
        
        //let c = SCContentSharingPicker.shared

        //let dat = Base32.decodeToData("KRUGKIDROVUWG2ZAMJZG653OEBTG66BANJ2W24DTEBXXMZLSEB2GQZJANRQXU6JAMRXWOLQ")
        //debugPrint(String(data: dat, encoding: .utf8)!)
    }
}
