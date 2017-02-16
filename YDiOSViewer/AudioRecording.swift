//
//  AudioRecording.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 2/14/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import Foundation

class AudioClip {
    var audioFile: URL!
    var isUploaded: Bool! = false
    var startTime: Float!
    var duration: Float!
    var isInline: Bool! = false
    var volume: Int!
    var userId: Int!
    var movieId: Int!
    var mediaId: String!
    var language: String!
    var chapter: String!
    var function: String!
    var index: Int!
    var isDeleted: Bool! = false
    var clipView: UIView!
    var timeLabelView: UILabel!
    var startHour: Int!
    var startMinutes: Int!
    var startSeconds: Float!
}

