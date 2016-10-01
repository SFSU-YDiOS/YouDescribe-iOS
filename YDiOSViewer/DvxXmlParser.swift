//
//  DvxXmlParser.swift
//  YDiOSViewer
//
//  Created by Rupal Khilari on 9/28/16.
//  Copyright © 2016 SFSU. All rights reserved.
//

import Foundation

/* A Generic XML Parser for DVX results */
class DvxXmlParser: NSObject, NSXMLParserDelegate {

    var currentElement:String = ""
    var passData:Bool=false
    var passName:Bool=false
    var parser = NSXMLParser()
    var resultArray:[AnyObject] = Array()
    var record:[String: AnyObject] = [:]
    var topLevelElem = ""
    var keyName:String = ""
    var valueName:String = ""
    var separator:String = ""
    
    func makeRequest(url:String, separator:String) -> Array<AnyObject> {

        let urlToSend: NSURL = NSURL(string: url)!
        self.separator = separator
        // Parse the XML
        parser = NSXMLParser(contentsOfURL: urlToSend)!
        parser.delegate = self
        
        let success:Bool = parser.parse()
        
        if success {
            print("Parsed successfully!")
            //print(resultArray)
            return resultArray
        } else {
            print("Failed to parse!")
        }
        return Array()
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        keyName = elementName
        //print("Element's name is \(elementName)")
        //print("Element's attributes are \(attributeDict)")
        //print("Qname is \(qName)")
        passName = true
    }

    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if (elementName == self.separator) {
            resultArray.append(record)
        }
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        if(passName){
            record[keyName] = string
        }
        
        if(passData)
        {
            print(string)
        }
    }
    
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        NSLog("Error in parsing XML: %@", parseError)
    }
}