//
//  Common.swift
//  VideoEditing
//
//  Created by Atik Hasan on 4/5/25.
//

import UIKit
import AVFoundation
import MobileCoreServices
import AVKit
import Photos

class CommonEditor{
    
    static var shared = CommonEditor()
    
    var CIFilterNames = [
        "CISharpenLuminance",
        "CIPhotoEffectChrome",
        "CIPhotoEffectFade",
        "CIPhotoEffectInstant",
        "CIPhotoEffectNoir",
        "CIPhotoEffectProcess",
        "CIPhotoEffectTonal",
        "CIPhotoEffectTransfer",
        "CISepiaTone",
        "CIColorClamp",
        "CIColorInvert",
        "CIColorMonochrome",
        "CISpotLight",
        "CIColorPosterize",
        "CIBoxBlur",
        "CIDiscBlur",
        "CIGaussianBlur",
        "CIMaskedVariableBlur",
        "CIMedianFilter",
        "CIMotionBlur",
        "CINoiseReduction"
    ]
    
    func convertImageToBW(filterName : String ,image:UIImage) -> UIImage {
        
        let filter = CIFilter(name: filterName)
        
        // convert UIImage to CIImage and set as input
        let ciInput = CIImage(image: image)
        filter?.setValue(ciInput, forKey: "inputImage")
        
        // get output CIImage, render as CGImage first to retain proper UIImage scale
        let ciOutput = filter?.outputImage
        let ciContext = CIContext()
        let cgImage = ciContext.createCGImage(ciOutput!, from: (ciOutput?.extent)!)
        
        return UIImage(cgImage: cgImage!)
    }
    
    //MARK: Thumbnail Image generate
    func generateThumbnail(path: URL) -> UIImage? {
        do {
            let asset = AVURLAsset(url: path, options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 10, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            return thumbnail
        } catch let error {
            print("Thumb image generate failed: \(error)")
            return nil
        }
    }
    
    //MARK: Add filter to video
    func addfiltertoVideo(strfiltername : String, strUrl : URL, success: @escaping ((URL) -> Void), failure: @escaping ((String?) -> Void)) {
        
        //FilterName
        let filter = CIFilter(name:strfiltername)
        
        //Asset
        let asset = AVAsset(url: strUrl)
        
        //Create Directory path for Save
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let fileName = "EffectVideo_\(UUID().uuidString).m4v"
        var  outputURL = documentDirectory.appendingPathComponent("EffectVideo/\(fileName)")
        
        // var outputURL = documentDirectory.appendingPathComponent("EffectVideo")
        do {
            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            outputURL = outputURL.appendingPathComponent("\(outputURL.lastPathComponent).m4v")
        }catch let error {
            failure(error.localizedDescription)
        }
        
        //Remove existing file
        self.deleteFile(outputURL)
        
        //AVVideoComposition
        let composition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
            
            // Clamp to avoid blurring transparent pixels at the image edges
            let source = request.sourceImage.clampedToExtent()
            filter?.setValue(source, forKey: kCIInputImageKey)
            
            // Crop the blurred output to the bounds of the original image
            let output = filter?.outputImage!.cropped(to: request.sourceImage.extent)
            
            // Provide the filter output to the composition
            request.finish(with: output!, context: nil)
            
        })
        
        //export the video to as per your requirement conversion
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else { return }
        exportSession.outputFileType = AVFileType.mov
        exportSession.outputURL = outputURL
        exportSession.videoComposition = composition
        
        exportSession.exportAsynchronously(completionHandler: {
            switch exportSession.status {
            case .completed:
                success(outputURL)
                
            case .failed:
                failure(exportSession.error?.localizedDescription)
                
            case .cancelled:
                failure(exportSession.error?.localizedDescription)
                
            default:
                failure(exportSession.error?.localizedDescription)
            }
        })
    }
    
    
    func deleteFile(_ filePath:URL) {
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            return
        }
        do {
            try FileManager.default.removeItem(atPath: filePath.path)
        }catch{
            fatalError("Unable to delete file: \(error) : \(#function).")
        }
    }
    
    // MARK: - Trim Video
    func trimVideo(sourceURL: URL, startTime: CMTime, endTime: CMTime, completion: @escaping (URL?) -> Void) {
        let asset = AVAsset(url: sourceURL)
        
        let filename = "trimmedVideo_\(UUID().uuidString).mp4"
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(nil)
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.timeRange = CMTimeRange(start: startTime, end: endTime)
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(outputURL)
            default:
                print("Export failed: \(exportSession.error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }
    
    // MARK: - Change video Playback speed
    func changeVideoSpeedInRange(url: URL, startTime: CMTime, endTime: CMTime, speed: Float64, completion: @escaping (_ url: URL?) -> Void) {
        let asset = AVAsset(url: url)
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            completion(nil)
            return
        }
        
        let composition = AVMutableComposition()
        guard let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(nil)
            return
        }
        
        videoCompositionTrack.preferredTransform = videoTrack.preferredTransform
        
        let targetRange = CMTimeRange(start: startTime, end: endTime)
        
        var currentTime = CMTime.zero
        
        // Before speed part
        if startTime > .zero {
            try? videoCompositionTrack.insertTimeRange(CMTimeRange(start: .zero, duration: startTime), of: videoTrack, at: currentTime)
            currentTime = CMTimeAdd(currentTime, startTime)
        }
        
        // Speed part
        try? videoCompositionTrack.insertTimeRange(targetRange, of: videoTrack, at: currentTime)
        let scaledDuration = CMTimeMultiplyByFloat64(targetRange.duration, multiplier: 1.0 / speed)
        videoCompositionTrack.scaleTimeRange(CMTimeRange(start: currentTime, duration: targetRange.duration), toDuration: scaledDuration)
        currentTime = CMTimeAdd(currentTime, scaledDuration)
        
        // After speed part
        let afterStart = endTime
        let afterDuration = CMTimeSubtract(asset.duration, endTime)
        
        if afterDuration > .zero {
            try? videoCompositionTrack.insertTimeRange(CMTimeRange(start: afterStart, duration: afterDuration), of: videoTrack, at: currentTime)
        }
        
        // --- Audio Handling ---
        if let audioTrack = asset.tracks(withMediaType: .audio).first,
           let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            
            var audioTime = CMTime.zero
            
            if startTime > .zero {
                try? audioCompositionTrack.insertTimeRange(CMTimeRange(start: .zero, duration: startTime), of: audioTrack, at: audioTime)
                audioTime = CMTimeAdd(audioTime, startTime)
            }
            
            try? audioCompositionTrack.insertTimeRange(targetRange, of: audioTrack, at: audioTime)
            audioCompositionTrack.scaleTimeRange(CMTimeRange(start: audioTime, duration: targetRange.duration), toDuration: scaledDuration)
            audioTime = CMTimeAdd(audioTime, scaledDuration)
            
            if afterDuration > .zero {
                try? audioCompositionTrack.insertTimeRange(CMTimeRange(start: afterStart, duration: afterDuration), of: audioTrack, at: audioTime)
            }
        }
        
        // Export
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("speedEdited_\(Int(Date().timeIntervalSince1970)).mp4")
        
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(nil)
            return
        }
        
        exporter.outputURL = outputURL
        exporter.outputFileType = .mp4
        exporter.shouldOptimizeForNetworkUse = true
        
        exporter.exportAsynchronously {
            DispatchQueue.main.async {
                if exporter.status == .completed {
                    completion(outputURL)
                } else {
                    print("Export failed: \(exporter.error?.localizedDescription ?? "Unknown error")")
                    completion(nil)
                }
            }
        }
    }
    
    // MARK: - Text Oberlay on Video
//    func addTextOverlayToVideo(videoURL: URL, completion: @escaping (URL?) -> Void) {
//        let asset = AVAsset(url: videoURL)
//        let composition = AVMutableComposition()
//        let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
//        
//        // Video Track
//        guard let videoTrack = asset.tracks(withMediaType: .video).first,
//              let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video,
//                                                                      preferredTrackID: kCMPersistentTrackID_Invalid) else {
//            print("Failed to load video track")
//            completion(nil)
//            return
//        }
//        
//        do {
//            try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
//            compositionVideoTrack.preferredTransform = videoTrack.preferredTransform
//        } catch {
//            print("Video insert error: \(error)")
//            completion(nil)
//            return
//        }
//        
//        // Audio Track (optional)
//        if let audioTrack = asset.tracks(withMediaType: .audio).first,
//           let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio,
//                                                                   preferredTrackID: kCMPersistentTrackID_Invalid) {
//            do {
//                try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
//            } catch {
//                print("Audio insert error: \(error)")
//            }
//        }
//        
//        // Layer Setup
//        let videoSize = videoTrack.naturalSize
//        let videoLayer = CALayer()
//        videoLayer.frame = CGRect(origin: .zero, size: videoSize)
//        
//        let parentLayer = CALayer()
//        parentLayer.frame = CGRect(origin: .zero, size: videoSize)
//        parentLayer.addSublayer(videoLayer)
//        
//        // Text Layer
//        let textLayer = CATextLayer()
//        textLayer.string = "Sample Watermark Text"
//        textLayer.fontSize = 28
//        textLayer.font = UIFont.systemFont(ofSize: 28)
//        textLayer.foregroundColor = UIColor.white.cgColor
//        textLayer.alignmentMode = .center
//        textLayer.frame = CGRect(x: 0, y: 50, width: videoSize.width, height: 100)
//        textLayer.contentsScale = UIScreen.main.scale
//        parentLayer.addSublayer(textLayer)
//        
//        // Video Composition
//        let videoComposition = AVMutableVideoComposition()
//        videoComposition.renderSize = videoSize
//        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
//        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
//            postProcessingAsVideoLayer: videoLayer,
//            in: parentLayer
//        )
//        
//        // Instruction
//        let instruction = AVMutableVideoCompositionInstruction()
//        instruction.timeRange = timeRange
//        
//        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
//        instruction.layerInstructions = [layerInstruction]
//        videoComposition.instructions = [instruction]
//        
//        // Export Path
//        let outputPath = NSTemporaryDirectory().appending("final_overlay.mov")
//        let outputURL = URL(fileURLWithPath: outputPath)
//        try? FileManager.default.removeItem(at: outputURL)
//        
//        // Export Session
//        guard let exportSession = AVAssetExportSession(asset: composition,
//                                                       presetName: AVAssetExportPresetHighestQuality) else {
//            print("Failed to create export session")
//            completion(nil)
//            return
//        }
//        
//        exportSession.outputURL = outputURL
//        exportSession.outputFileType = .mov
//        exportSession.shouldOptimizeForNetworkUse = true
//        exportSession.videoComposition = videoComposition
//        
//        exportSession.exportAsynchronously {
//            DispatchQueue.main.async {
//                switch exportSession.status {
//                case .completed:
//                    print("Export complete at: \(outputURL)")
//                    completion(outputURL)
//                    
//                    // Optional: Save to Photos
//                    PHPhotoLibrary.shared().performChanges {
//                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
//                    } completionHandler: { success, error in
//                        if success {
//                            print("Video saved to Photos")
//                        } else {
//                            print("Photo save error: \(String(describing: error))")
//                        }
//                    }
//                    
//                case .failed, .cancelled:
//                    print("Export failed: \(exportSession.error?.localizedDescription ?? "unknown error")")
//                    completion(nil)
//                default:
//                    break
//                }
//            }
//        }
//    }


    func addTextOverlayToVideo(videoURL: URL,
                               overlayTextView: UITextView,
                               transformInfo: TransformInfo,
                               startTime: CMTime,
                               endTime: CMTime,
                               completion: @escaping (URL?) -> Void) {
        
        let asset = AVAsset(url: videoURL)
        let composition = AVMutableComposition()
        let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first,
              let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video,
                                                                      preferredTrackID: kCMPersistentTrackID_Invalid) else {
            print("Failed to load video track")
            completion(nil)
            return
        }
        
        do {
            try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
        } catch {
            print("Video insert error: \(error)")
            completion(nil)
            return
        }
        
        let videoSize = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        let fixedVideoSize = CGSize(width: abs(videoSize.width), height: abs(videoSize.height))
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: fixedVideoSize)
        
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: fixedVideoSize)
        parentLayer.addSublayer(videoLayer)
        
        let textLayer = CATextLayer()
        textLayer.string = overlayTextView.text
        textLayer.font = CGFont("Helvetica-Bold" as CFString)
        textLayer.fontSize = 90
        textLayer.foregroundColor = overlayTextView.textColor?.cgColor
        textLayer.backgroundColor = UIColor.white.cgColor
        textLayer.alignmentMode = .center
        textLayer.contentsScale = UIScreen.main.scale
        
        let playerViewSize = overlayTextView.superview?.frame.size ?? fixedVideoSize
        let viewFrame = overlayTextView.frame
        let xRatio = fixedVideoSize.width / playerViewSize.width
        let yRatio = fixedVideoSize.height / playerViewSize.height
        
        let scaledOrigin = CGPoint(
            x: viewFrame.origin.x * xRatio,
            y: (playerViewSize.height - viewFrame.origin.y - viewFrame.height) * yRatio
        )
        let scaledSize = CGSize(width: viewFrame.width * xRatio, height: viewFrame.height * yRatio)
        let scaledFrame = CGRect(origin: scaledOrigin, size: scaledSize)
        
        textLayer.frame = scaledFrame

        // TransformInfo ব্যবহার করে transform apply করো
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: transformInfo.translation.x * xRatio,
                                           y: -transformInfo.translation.y * yRatio) // UIKit vs CoreAnimation Y-axis
        transform = transform.scaledBy(x: transformInfo.scale, y: transformInfo.scale)
        transform = transform.rotated(by: transformInfo.rotation)
        
        let affine = CATransform3DMakeAffineTransform(transform)
        textLayer.transform = affine
        
        parentLayer.addSublayer(textLayer)
        
        // Opacity animation
        var beginTime = CMTimeGetSeconds(startTime)
        if beginTime < 1 {
            beginTime += 0.1
        }
        textLayer.opacity = 0
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1
        opacityAnimation.toValue = 0
        opacityAnimation.beginTime = beginTime
        opacityAnimation.duration = CMTimeGetSeconds(endTime - startTime)
        opacityAnimation.isRemovedOnCompletion = false
        opacityAnimation.fillMode = .forwards
        textLayer.add(opacityAnimation, forKey: "opacityAnimation")
        
        // Video composition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = fixedVideoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = timeRange
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        layerInstruction.setTransform(videoTrack.preferredTransform, at: .zero)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        print("playerViewSize: \(playerViewSize)")
        print("overlayTextView.frame: \(overlayTextView.frame)")
        print("scaledFrame: \(scaledFrame)")

        // Export
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("final_overlay.mov")
        try? FileManager.default.removeItem(at: outputURL)
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            print("Export session creation failed")
            completion(nil)
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.videoComposition = videoComposition
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    print("Export successful: \(outputURL)")
                    completion(outputURL)
                case .failed:
                    print("Export failed: \(exportSession.error?.localizedDescription ?? "Unknown error")")
                    completion(nil)
                case .cancelled:
                    print("Export cancelled")
                    completion(nil)
                default:
                    break
                }
            }
        }
    }




    // MARK: - Save Video in Document Directory
    func SaveToDocumentsDirectory(from sourceURL: URL) -> URL? {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let destinationURL = documentsDirectory.appendingPathComponent("SavedVideo_\(UUID().uuidString).mp4")
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            print("Video saved to: \(destinationURL)")
            return destinationURL
        } catch {
            print("Failed to copy video: \(error.localizedDescription)")
            return nil
        }
    }
    
}



// MARK: - Extention
extension CMTime {
    var displayString: String {
        let offset = TimeInterval(seconds)
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.hour, .minute, .second]
        
        return formatter.string(from: offset) ?? "00:00:00"
    }
    
}

extension AVAsset {
    var fullRange: CMTimeRange {
        return CMTimeRange(start: .zero, duration: duration)
    }
    func trimmedComposition(_ range: CMTimeRange) -> AVAsset {
        guard CMTimeRangeEqual(fullRange, range) == false else {return self}
        
        let composition = AVMutableComposition()
        try? composition.insertTimeRange(range, of: self, at: .zero)
        
        if let videoTrack = tracks(withMediaType: .video).first {
            composition.tracks.forEach {$0.preferredTransform = videoTrack.preferredTransform}
        }
        return composition
    }
}


// MARK: - Face Editor (apply blur filter all frame of video)
extension CommonEditor {
    func extractAllFrames(from videoURL: URL, completion: @escaping ([UIImage]) -> Void) {
        var images: [UIImage] = []

        let asset = AVAsset(url: videoURL)
        guard let track = asset.tracks(withMediaType: .video).first else {
            print("⚠️ No video track found")
            completion([])
            return
        }

        do {
            let reader = try AVAssetReader(asset: asset)

            let outputSettings: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]

            let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
            reader.add(trackOutput)
            reader.startReading()

            while let sampleBuffer = trackOutput.copyNextSampleBuffer(),
                  let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {

                let ciImage = CIImage(cvImageBuffer: imageBuffer)
                let context = CIContext()

                if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                    let uiImage = UIImage(cgImage: cgImage)
                    images.append(uiImage)
                }
            }

            reader.cancelReading() // always good to clean up
            completion(images)

        } catch {
            print("❌ Failed to read video frames: \(error.localizedDescription)")
            completion([])
        }
    }
}
