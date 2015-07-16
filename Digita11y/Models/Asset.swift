import Foundation
import AVFoundation
import RWFramework

enum MediaType {
  case None
  case Text
  case Photo
  case Audio
}

private var TextCache = [String:String]()

struct Asset {
  var assetDescription = ""
  var submitted: Bool = false
  var volume = 0
  var project = 0
  var assetID = 0
  var mediaType = MediaType.None
  var tagIDs: [Int] = []
  var fileURL = NSURL()
  var audioLength: Float = 0.0
  var text: String? {
    get {
      return TextCache[fileURL.absoluteString ?? ""]
    }
  }

  init(json: JSON) {
    assetDescription = json["description"].string ?? ""
    submitted = json["submitted"].boolValue ?? false
    volume = json["volume"].int ?? 0
    project = json["project"].int ?? 0
    assetID = json["asset_id"].int ?? 0
    audioLength = json["audio_length_in_seconds"].float ?? 0

    tagIDs = json["tag_ids"].array?.map { $0.int ?? 0 } ?? []

    var base = RWFrameworkConfig.getConfigValueAsString("base_url")
    var path = (json["file"].string ?? "")
    if base.hasSuffix("/") && path.hasPrefix("/") {
      path.removeAtIndex(path.startIndex)
    }
    var strURL = base + path
    fileURL = NSURL(string: strURL) ?? NSURL()

    if json["media_type"].string == "text" {
      mediaType = .Text

      if let url = fileURL.absoluteString {
        if TextCache[url] == nil {
          requestAssetText(url) { text in
            TextCache[url] = text
          }
        }
      }
    } else if json["media_type"].string == "photo" {
      mediaType = .Photo
    } else if json["media_type"].string == "audio" {
      mediaType = .Audio
    } else {
      debugPrintln(json["media_type"].string)
    }
  }
}

class AssetPlayer : NSObject {
  var player : AVPlayer?
  var asset: Asset

  var isPlaying: Bool {
    get {
      return self.player?.rate == 1.0
    }
  }

  init(asset: Asset) {
    self.asset = asset

    var item = AVPlayerItem(URL: asset.fileURL)
    player = AVPlayer(playerItem: item)
    super.init()
  }
}

//{
//  "description" : "",
//  "volume" : 1,
//  "audio_length_in_seconds" : null,
//  "file" : "\/rwmedia\/20150312-164018-190.txt",
//  "project" : 2,
//  "asset_id" : 58,
//  "filename" : "20150312-164018-190.txt",
//  "longitude" : -122.0312186,
//  "submitted" : true,
//  "latitude" : 37.33233141,
//  "weight" : 50,
//  "media_type" : "text",
//  "tag_ids" : [
//
//  ],
//  "language" : "en",
//  "created" : "2015-03-12T16:40:18",
//  "session_id" : 190,
//  "loc_description" : [
//
//  ]
//}