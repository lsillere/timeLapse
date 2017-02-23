//
//  TimeLapseBuilder.swift
//  testapp2
//
//  Created by Loic Sillere on 26/11/2016.
//  Copyright © 2016 Loic Sillere. All rights reserved.
//

import AVFoundation
import UIKit

let kErrorDomain = "TimeLapseBuilder"
let kFailedToStartAssetWriterError = 0
let kFailedToAppendPixelBufferError = 1

class TimeLapseBuilder: NSObject {
    let photoURLs: [String]
    var videoWriter: AVAssetWriter?
    let orientation: UIImageOrientation
    var videoNumber: Int
    let settings = Settings()
    
    let inputSize: CGSize
    let outputSize: CGSize
    let videoOutputURL: URL
    let videoSettings: [String : AnyObject]
    
    
    
    /*let videoWriterInput: AVAssetWriterInput
    let sourceBufferAttributes: [String : Any]
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor
    var frameCount: Int64 = 0*/
    
    
    
    init(photoURLs: [String], orientation: UIImageOrientation, videoNumber: Int) {
        self.photoURLs = photoURLs
        self.orientation = orientation
        self.videoNumber = videoNumber
        
        let width: Int
        let height: Int
        
        switch settings.videoQuality {
        case "720p":
            width = 1280
            height = 720
        case "480p":
            width = 720
            height = 483
        default:
            width = 1920
            height = 1080
        }
        
        // Video dimension based on photos orientation
        if(orientation == UIImageOrientation.up || orientation == UIImageOrientation.down) {
            /*inputSize = CGSize(width: 4032, height: 3024)
             outputSize = CGSize(width: 1280, height: 720)*/
            self.inputSize = CGSize(width: 1920, height: 1080)
            self.outputSize = CGSize(width: width, height: height)
        } else {
            /*inputSize = CGSize(width: 3024, height: 4032)
             outputSize = CGSize(width: 3024/3, height: 4032/3)*/
            self.inputSize = CGSize(width: 1080, height: 1920)
            self.outputSize = CGSize(width: height, height: width)
        }
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        self.videoOutputURL = URL(fileURLWithPath: documentsPath.appendingPathComponent("TimeLapseVideo/AssembledVideo"+String(videoNumber)+".mov"))
        print("TimeLapseBuilderVideoOutputUrl : \(self.videoOutputURL)")
        
        self.videoSettings = [
            AVVideoCodecKey  : AVVideoCodecH264 as AnyObject,
            AVVideoWidthKey  : outputSize.width as AnyObject,
            AVVideoHeightKey : outputSize.height as AnyObject,
            //        AVVideoCompressionPropertiesKey : [
            //          AVVideoAverageBitRateKey : NSInteger(1000000),
            //          AVVideoMaxKeyFrameIntervalKey : NSInteger(16),
            //          AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel
            //        ]
        ]
        
        
        
        
        
        
        /*self.videoWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
        
        self.sourceBufferAttributes = [
            (kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32ARGB),
            (kCVPixelBufferWidthKey as String): Float(inputSize.width),
            (kCVPixelBufferHeightKey as String): Float(inputSize.height)] as [String : Any]
        self.pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: self.videoWriterInput,
            sourcePixelBufferAttributes: sourceBufferAttributes
        )*/

        
        
    }
    
    func removeVideoIfExist() {
        do {
            try FileManager.default.removeItem(at: self.videoOutputURL)
        } catch let writerError as NSError {
            print(writerError)
        }
    }
    
    func build(_ progress: @escaping ((Progress) -> Void), success: @escaping ((URL) -> Void), failure: ((NSError) -> Void)) {
        var error: NSError?
        
        do {
            try videoWriter = AVAssetWriter(outputURL: videoOutputURL, fileType: AVFileTypeQuickTimeMovie)
        } catch let writerError as NSError {
            error = writerError
            videoWriter = nil
        }
        
        if let videoWriter = videoWriter {
            
            let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
            
            let sourceBufferAttributes = [
                (kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32ARGB),
                (kCVPixelBufferWidthKey as String): Float(inputSize.width),
                (kCVPixelBufferHeightKey as String): Float(inputSize.height)] as [String : Any]
            
            let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: videoWriterInput,
                sourcePixelBufferAttributes: sourceBufferAttributes
            )
            
            assert(videoWriter.canAdd(videoWriterInput))
            videoWriter.add(videoWriterInput)
            
            if videoWriter.startWriting() {
                videoWriter.startSession(atSourceTime: kCMTimeZero)
                assert(pixelBufferAdaptor.pixelBufferPool != nil)
                print("test startWriting")
                let media_queue = DispatchQueue(label: "mediaInputQueue")
                
                videoWriterInput.requestMediaDataWhenReady(on: media_queue) {
                    let fps: Int32 = 30
                    let frameDuration = CMTimeMake(1, fps)
                    let currentProgress = Progress(totalUnitCount: Int64(self.photoURLs.count))
                    
                    var frameCount: Int64 = 0
                    var remainingPhotoURLs = [String](self.photoURLs)
                    
                    while videoWriterInput.isReadyForMoreMediaData && !remainingPhotoURLs.isEmpty {
                        let nextPhotoURL = remainingPhotoURLs.remove(at: 0)
                        let lastFrameTime = CMTimeMake(frameCount, fps)
                        let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                        
                        if !self.appendPixelBufferForImageAtURL(nextPhotoURL, pixelBufferAdaptor: pixelBufferAdaptor, presentationTime: presentationTime) {
                            error = NSError(
                                domain: kErrorDomain,
                                code: kFailedToAppendPixelBufferError,
                                userInfo: ["description": "AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer"]
                            )
                            print("error")
                            
                            break
                        }
                        
                        frameCount += 1
                        
                        currentProgress.completedUnitCount = frameCount
                        progress(currentProgress)
                    }
                    
                    videoWriterInput.markAsFinished()
                    videoWriter.finishWriting {
                        if error == nil {
                            success(self.videoOutputURL)
                        }
                        
                        self.videoWriter = nil
                    }
                }
            } else {
                error = NSError(
                    domain: kErrorDomain,
                    code: kFailedToStartAssetWriterError,
                    userInfo: ["description": "AVAssetWriter failed to start writing"]
                )
            }
        }
        
        if let error = error {
            failure(error)
        }
    }
    
    func appendPixelBufferForImageAtURL(_ url: String, pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor, presentationTime: CMTime) -> Bool {
        var appendSucceeded = false
        //print("pixelBufferAdaptor.pixelBufferPool: ", pixelBufferAdaptor.pixelBufferPool)
        autoreleasepool {
            if //let url = URL(string: url),
                //let imageData = try? Data(contentsOf: url),
                let imageData = FileManager.default.contents(atPath: url),
                let image = UIImage(data: imageData),
                let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool {
                    let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: 1)
                    let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(
                        kCFAllocatorDefault,
                        pixelBufferPool,
                        pixelBufferPointer
                    )
                
                    if let pixelBuffer = pixelBufferPointer.pointee, status == 0 {
                        fillPixelBufferFromImage(image: image, pixelBuffer: pixelBuffer)
                    
                        appendSucceeded = pixelBufferAdaptor.append(
                            pixelBuffer,
                            withPresentationTime: presentationTime
                        )
                    
                        pixelBufferPointer.deinitialize()
                    } else {
                        NSLog("error: Failed to allocate pixel buffer from pool")
                    }
                
                    pixelBufferPointer.deallocate(capacity: 1)
            }
        }
        
        return appendSucceeded
    }
    
    func fillPixelBufferFromImage(image: UIImage, pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: pixelData,
            width: Int(image.size.width),
            height: Int(image.size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        )
        
        
        // CGImage transformation for
        var transform = CGAffineTransform.identity
        switch image.imageOrientation {
            
        case .down, .downMirrored:
            transform = transform.translatedBy(x: image.size.width, y: image.size.height)
            transform = transform.rotated(by: CGFloat(M_PI))
            //print("down")
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.rotated(by: CGFloat(M_PI_2))
            //print("left")
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: image.size.height)
            transform = transform.rotated(by: CGFloat(-M_PI_2))
            //print("right")
        case .up, .upMirrored:
            //print("up")
            break
        }
        
        context?.concatenate(transform)
        
        
        switch image.imageOrientation {
        case UIImageOrientation.left, UIImageOrientation.leftMirrored, UIImageOrientation.right, UIImageOrientation.rightMirrored:
            context?.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width))
            break
        default:
            context?.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
            break
        }
        
        //context?.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width))
        
        /*if(orientation == UIImageOrientation.up || orientation == UIImageOrientation.down) {
            context?.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        } else {
            context?.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width))
        }*/
        /*let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        context?.draw(image.cgImage!, in: rect)
        */
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
    }
    
    
    
    
    /*func prepBuild() {
        do {
            try self.videoWriter = AVAssetWriter(outputURL: videoOutputURL, fileType: AVFileTypeQuickTimeMovie)
        } catch let writerError as NSError {
            print(writerError)
            self.videoWriter = nil
        }
        if self.videoWriter != nil {
            self.videoWriterInput.expectsMediaDataInRealTime = true

            assert(self.videoWriter!.canAdd(videoWriterInput))
            self.videoWriter!.add(videoWriterInput)
        }
        /*self.pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoWriterInput,
            sourcePixelBufferAttributes: sourceBufferAttributes
        )*/
        print("prepBuild")
        self.videoWriter!.startWriting()
        print("test startWriting")
            self.videoWriter!.startSession(atSourceTime: kCMTimeZero)
        print("test startsession")
            assert(self.pixelBufferAdaptor.pixelBufferPool != nil)
        print("test assert")
        
        
    }*/
    
    /*func endBuild() {
        self.videoWriterInput.markAsFinished()
        self.videoWriter!.finishWriting()
    }
    
    //videoWriter = nil
    }*/

    
    /*func buildNew(_ progress: @escaping ((Progress) -> Void), success: @escaping ((URL) -> Void), failure: ((NSError) -> Void), nextPhotoURL: String) {
        var error: NSError?
        
        print("VideoWritter: ", self.videoWriter!)
        if self.videoWriter != nil {
                let media_queue = DispatchQueue(label: "mediaInputQueue")
                
                //self.videoWriterInput.requestMediaDataWhenReady(on: media_queue) {
                    let fps: Int32 = 30
                    let frameDuration = CMTimeMake(1, fps)
                    let currentProgress = Progress(totalUnitCount: Int64(self.photoURLs.count))
                    
                    //var remainingPhotoURLs = [String](self.photoURLs)
                    
                   if(self.videoWriterInput.isReadyForMoreMediaData) {
                        //let nextPhotoURL = remainingPhotoURLs.remove(at: 0)
                        let lastFrameTime = CMTimeMake(self.frameCount, fps)
                        let presentationTime = self.frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                        
                        if !self.appendPixelBufferForImageAtURL(nextPhotoURL, pixelBufferAdaptor: self.pixelBufferAdaptor, presentationTime: presentationTime) {
                            error = NSError(
                                domain: kErrorDomain,
                                code: kFailedToAppendPixelBufferError,
                                userInfo: ["description": "AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer"]
                            )
                            print("error")
                        }
                        
                        self.frameCount += 1
                        
                        currentProgress.completedUnitCount = self.frameCount
                        progress(currentProgress)
                    }
                //}
            
        }
        
        if let error = error {
            failure(error)
        }
    }*/
}
