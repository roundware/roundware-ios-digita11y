import Foundation
class ChooseExhibitViewModel: BaseViewModel  {
    let data: RWData
    let project: Project
    var uiGroup: UIGroup
    let uiItems: [UIItem]
    let tags: [Tag]
    let title: String

    var selectedTag: Tag? {
        didSet {
            self.uiGroup.selectedUIItem = self.uiGroup.uiItems.filter({$0.tagId == self.selectedTag!.id}).first
            data.updateUIGroup(self.uiGroup)
            DebugLog("selected ui item for exhibitions uigroup at index \(self.uiGroup.index) set to \(String(describing: self.uiGroup.selectedUIItem))")
        }
    }

    init(data: RWData) {
        self.data = data
        self.project = data.selectedProject!

        //TODO error handle
        self.uiGroup = data.getUIGroupForIndexAndMode(1, mode: "listen")!
        self.uiItems = data.getRelevantUIItems(uiGroup)
        self.tags = data.getTagsForUIItems(self.uiItems)
        self.title = "Welcome to the \(self.project.name)! \n \(self.uiGroup.headerTextLoc)"
    }



    //TODO remove these and refactor
    func numberOfItems() -> Int {
         return self.tags.count
    }

    func titleForIndex(_ index:Int) -> String{
        return self.tags[index].locMsg
    }

    func selectedIndex(_ index:Int) {
        self.selectedTag = self.tags[index]

    }

    func selectedTitle(_ title:String) {
        self.selectedTag = self.tags.filter{ $0.locMsg == title}.first!
    }
}
