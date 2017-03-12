//
//  DvxUpload.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 3/2/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import Foundation
import MobileCoreServices

extension Data {

    // Append string to NSMutableData
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

class DvxUpload {

    // Creates a multipart request required for adding a new clip along with its metadata
    func createRequest(_ params: [String: String], uploadURL: URL) throws -> URLRequest {

        let boundary = generateBoundaryString()
        
        let url = URL(string: Constants.API_BASE_URL + "clip/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let path1 = uploadURL.path
        request.httpBody = try createBody(with: params, filePathKey: "filedata", paths: [path1], boundary: boundary)
        return request
    }

    // Create body of the multipart/form-data request
    func createBody(with parameters: [String: String]?, filePathKey: String, paths: [String], boundary: String) throws -> Data {
        var body = Data()

        if parameters != nil {
            for (key, value) in parameters! {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append("\(value)\r\n")
            }
        }

        for path in paths {
            let url = URL(fileURLWithPath: path)
            let filename = url.lastPathComponent
            let data = try Data(contentsOf: url)
            let mimetype = getMp3MimeType()
            
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"\(filename)\"\r\n")
            body.append("Content-Type: \(mimetype)\r\n\r\n")
            body.append(data)
            body.append("\r\n")
        }
        
        body.append("--\(boundary)--\r\n")
        return body
    }
    
    // Create boundary string for multipart/form-data request
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }

    // Return RFC defined mime type for .mp3
    func getMp3MimeType() -> String {
        return "audio/mpeg"
    }
    // Determine mime type on the basis of extension of a file.
    func mimeType(for path: String) -> String {
        let url = NSURL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
    
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream";
    }
}
