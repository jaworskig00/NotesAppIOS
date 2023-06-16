import CoreData
import UIKit

@objc(Note)

class Note: NSManagedObject {
    
    @NSManaged var id: NSNumber!
    @NSManaged var title: String!
    @NSManaged var desc: String!
    @NSManaged var geo: String!
    @NSManaged var image: UIImage!
    @NSManaged var is_deleted: NSNumber!
}
