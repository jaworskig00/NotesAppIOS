import UIKit
import CoreData

var noteList = [Note]()
var nonDeletedNoteList = [Note]()

class TableViewController: UITableViewController, UINavigationControllerDelegate {
    
    var firstLoad = true
    
    override func viewDidLoad() {
        if (firstLoad) {
            firstLoad = false
            let appDelegete = UIApplication.shared.delegate as! AppDelegate
            let context: NSManagedObjectContext = appDelegete.persistentContainer.viewContext
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
            
            do {
                let results: NSArray = try context.fetch(request) as NSArray
                for result in results {
                    let note = result as! Note
                    noteList.append(note)
                }
            } catch {
                print("context fetch failed")
            }
        }
        
        nonDeletedNoteList = noteList.filter({ $0.is_deleted == NSNumber(value: false) })
        
        nonDeletedNoteList.sort(by: {
            if let title1 = $0.title, let title2 = $1.title {
                return title1 < title2
            } else {
                return $0.title != nil
            }
        })
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let noteCell = tableView.dequeueReusableCell(withIdentifier: "noteCellID", for: indexPath) as! CellViewController
        
        let thisNote: Note!
        thisNote = nonDeletedNoteList[indexPath.row]
        
        noteCell.titleLabel.text = thisNote.title
        noteCell.descLabel.text = thisNote.desc
        noteCell.noteImageView.image = thisNote.image
        
        return noteCell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nonDeletedNoteList.count
    }
    
    override func viewDidAppear(_ animated: Bool) {
        nonDeletedNoteList = noteList.filter({ $0.is_deleted == NSNumber(value: false) })
        
        nonDeletedNoteList.sort(by: {
            if let title1 = $0.title, let title2 = $1.title {
                return title1 < title2
            } else {
                return $0.title != nil
            }
        })

        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "editNote", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "editNote") {
            let indexPath = tableView.indexPathForSelectedRow!
            let noteDetail = segue.destination as? NoteViewController
            let selectedNote: Note!
            selectedNote = nonDeletedNoteList[indexPath.row]
            noteDetail!.selectedNote = selectedNote
            
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}
