import Foundation
import SwiftyJSON

struct Tag {
    var id: Int = 0
    var relationships: [String:Any]
    var value: String = ""
    var locMsg: String = ""
    var description: String = ""
    var data: String = ""
    var tagCategory: Int = 0

    init(json: JSON) {
        id = json["id"].int ?? 0
        // relationships = json["relationships"].dictionaryObject as [String : AnyObject?]? ?? [:]
        relationships = ["":""] // json["relationships"].dictionaryObject! as [String : Any?] ?: [:]
        value = json["value"].string ?? ""
        locMsg = json["loc_msg"].string ?? ""
        description = json["description"].string ?? ""
        data = json["data"].string ?? ""
        tagCategory = json["tagCategory"].int ?? 0
    }
}
