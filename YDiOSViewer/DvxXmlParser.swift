import Foundation

/* A Generic XML Parser for DVX results */
class DvxXmlParser: NSObject, XMLParserDelegate {

    var currentElement:String = ""
    var passData:Bool=false
    var passName:Bool=false
    var parser = XMLParser()
    var resultArray:[AnyObject] = Array()
    var record:[String: AnyObject] = [:]
    var topLevelElem = ""
    var keyName:String = ""
    var valueName:String = ""
    var separator:String = ""

    func makeRequest(_ url:String, separator:String) -> Array<AnyObject> {

        URLCache.shared.removeAllCachedResponses()
        let urlToSend: URL = URL(string: url)!
        self.separator = separator
        // Parse the XML
        parser = XMLParser(contentsOf: urlToSend)!
        parser.delegate = self
        
        let success:Bool = parser.parse()

        if success {
            print("Parsed successfully")
            return resultArray
        } else {
            print("Failed to parse!")
        }
        return Array()
    }

    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        keyName = elementName
        //print("Element's name is \(elementName)")
        //print("Element's attributes are \(attributeDict)")
        //print("Qname is \(qName)")
        passName = true
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if (elementName == self.separator) {
            resultArray.append(record as AnyObject)
            record = [:]
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if(passName){
            if record[keyName] != nil {
                record[keyName] = (record[keyName] as! String + string) as AnyObject
            }
            else {
                record[keyName] = string as AnyObject?
            }
        }
        if(passData)
        {
            print(string)
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print(parseError)
    }
}
