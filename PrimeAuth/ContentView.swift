//
//  ContentView.swift
//  PrimeAuth
//
//  Created by Z Salti on 7/19/25.
//

import SwiftUI
import SwiftData
import ScreenCaptureKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    //@Query(animation: .bouncy) private var profiles: [Profile]
    @Query(sort: \Profile.accessCount, order: .reverse, animation: .bouncy) private var profiles: [Profile]
    
    @State private var showNewProfileView = false
    @State private var newProfileName: String = ""
    @StateObject private var scrnshotQrer = ScreenshotQR()
    
    var body: some View {
        
        VStack {
            
            ScrollView {
                VStack {
                    ForEach(profiles) { profile in
                        HStack{
                            //Label(profile.name, systemImage: profile.isSelected ? "checkmark.app" : "")
                            Button {
                                let code = profile.get2Auth6DigitCode()
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(code ?? "", forType: .string)
                                // put recenently used profile at the top while normalizing accessCounts so usage details aren't stored on disk except that a profile may be used more than another profile
                                // we don't want it so that "the person accessed this x amount of times and that y amount of times" is aparent on the db
                                var i = 0
                                for prof in profiles.reversed() {
                                    if (prof == profile) {
                                        continue
                                    }
                                    prof.accessCount = i
                                    i += 1
                                }
                                profile.accessCount = i
                            } label: {
                                Image(systemName: "document.on.clipboard").imageScale(.small)
                            }
                            Text(profile.name)
                            Button {
                                // delete and normalize profile list
                                var i = 0
                                for prof in profiles.reversed() {
                                    if (prof == profile) {
                                        modelContext.delete(prof)
                                        continue
                                    }
                                    prof.accessCount = i
                                    i += 1
                                }
                            } label: {
                                Image(systemName: "trash").imageScale(.small)
                            }
                        }
                    }
                }
            }.scrollIndicators(.never)
            
            /*Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")*/
            if !showNewProfileView {
                Button("New Profile") {
                    showNewProfileView = true
                }
            } else {
                Button("Cancel New Profile") {
                    scrnshotQrer.qrString = ""
                    newProfileName = ""
                    showNewProfileView = false
                }
            }
            
            if showNewProfileView {
                TextField(text: $newProfileName, prompt: Text("New Profile Name")) {}
                HStack {
                    SecureField(text: $scrnshotQrer.qrString, prompt: Text("Secret key if no QR")) {}
                    Button("QR Scan", systemImage: "qrcode.viewfinder", action: {
                        let picker = SCContentSharingPicker.shared
                        picker.add(scrnshotQrer)
                        picker.isActive = true
                        picker.present()
                    })
                }
                Button("Create New Profile") {
                    if !newProfileName.isEmpty && !scrnshotQrer.qrString.isEmpty {
                        if let newProfile = Profile(name: newProfileName, secret: scrnshotQrer.qrString, accessCount: profiles.first != nil ? profiles[0].accessCount + 1 : 0) {
                            modelContext.insert(newProfile)
                            scrnshotQrer.qrString = ""
                            newProfileName = ""
                            showNewProfileView = false
                        }
                    }
                }
            }
            Spacer()
        }
        .padding()
    }
    
}

/*
 Avoided use of screencapture tool because it either saves screenshot (with sensitive data) to clipboard or filesystem, all things
 that may be too insecure.
 If you wan't to do screenshots with the hand drawing crop thingy but securely, do some sort of ld preload injection thingy
 on the screencapture tool so that instead of writing to a file in plaintext or copying to clipboard in plaintext, it encrypts it first
 to our liking.
 Though, our 6 digit keys are being copied to clipboard for ease of use. (ofcourse the main secret key is higher priority of protecting than the temporary 6 digit key)
 */

class ScreenshotQR: NSObject, SCContentSharingPickerObserver, ObservableObject {
    @Published var qrString = ""
    
    func contentSharingPicker(_ picker: SCContentSharingPicker, didCancelFor: SCStream?) {
        picker.isActive = false
    }
    func contentSharingPicker(_ picker: SCContentSharingPicker, didUpdateWith: SCContentFilter, for: SCStream?) {
        //debugPrint(didUpdateWith.includedDisplays)
        //debugPrint(didUpdateWith.includedWindows)
        //debugPrint(didUpdateWith.includedApplications)
        let conf = SCStreamConfiguration()
        conf.showsCursor = false
        picker.isActive = false
        
        // use the dimensions from what was picked except upscaled incase QR code features aren't thick enough
        conf.width = Int(didUpdateWith.contentRect.width) * 2
        conf.height = Int(didUpdateWith.contentRect.height) * 2

        /*DispatchQueue.main.async {
            self.qrString = "asdfasdfsf"
            debugPrint("asdfasdfasdfasdflkjdsflk;asdjf;aldskjf;l")
        }
        debugPrint(self.qrString)*/
        Task {
            if let screenshot = try? await SCScreenshotManager.captureImage(contentFilter: didUpdateWith, configuration: conf) {
                let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!
                let img = CIImage(cgImage: screenshot)
                let matchSecretRegex = /secret=([^&=\n\0]+)/.ignoresCase()
                for feature in detector.features(in: img) as! [CIQRCodeFeature] {
                    //debugPrint(feature.messageString!)
                    let featureString = feature.messageString!
                    let matchOp = featureString.firstMatch(of: matchSecretRegex)
                    //let secret = match != nil ? String(match!.output.1).uppercased() : featureString.uppercased()
                    if let match = matchOp {
                        await MainActor.run {
                            self.qrString = String(match.output.1)
                        }
                        break
                    }
                    // if no match, then maybe its in the next, if any, QR code
                }
                //self.qrString = fst
                //picker.isActive = false
            }
        }
    }
    
    func contentSharingPickerStartDidFailWithError(_ error: any Error) {
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Profile.self, inMemory: true)
     
}
