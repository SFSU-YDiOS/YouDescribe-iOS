//
//  SocialHelper.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 2/26/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import Foundation
import Social

class SocialHelper {
    
    var mediaId : String!
    var preferredAuthor: String!
    var movieTitle: String!

    init(mediaId: String, author: String, movieTitle: String) {
        self.mediaId = mediaId
        self.preferredAuthor = author
        self.movieTitle = movieTitle
    }

    func copyEmbedCodeToClipboard() {
        UIPasteboard.general.string = getEmbedCode()
    }

    func copyLinkToClipboard() {
        UIPasteboard.general.string = getShareCode()
    }

    func getShareOnSocialMediaObject() -> [Any] {
        //Set the default sharing message.
        let message = "Watch \(self.movieTitle!) with description on YouDescribe! "
        //Set the link to share.
        let link = NSURL(string: self.getShareCode())
        let objectsToShare = [message + (link?.absoluteString!)!] as [Any]
        return objectsToShare
    }

    func getRequestDescriptionObject() -> [Any] {
        //Set the default request description message
        let message = "Requesting a description of  \(self.movieTitle!) at "
        //Set the link to share.
        let link = NSURL(string: self.getCreateCode())
        let hashTags = "\n#YouDescribe #ydrequest "

        let objectsToShare = [message + (link?.absoluteString!)! + hashTags] as [Any]
        return objectsToShare
    }

    func getEmbedCode() -> String {
        return "<span itemscope='' itemtype='http://schema.org/VideoObject'> " +
            "<meta itemprop='accessibilityFeature' content='audioDescription'/>" +
            "<meta itemprop='name' content=\(self.movieTitle!) />" +
            "<iframe width='480' height='360' " +
            "src='http://youdescribe.org/player.php?w=480&h=360&v=\(self.mediaId!)&d=\(self.preferredAuthor!)&embed=true'> " +
            "</iframe>" +
        "</span>"
    }
    
    func getShareCode() -> String {
        return "http://youdescribe.org/player.php?v=\(self.mediaId!)&prefer_d=\(self.preferredAuthor!)"
    }
    
    func getCreateCode() -> String {
        return "http://youdescribe.org/addCreate.php?v=\(self.mediaId!)"
    }
}
