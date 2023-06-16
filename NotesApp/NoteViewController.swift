import UIKit
import CoreData
import CoreLocation
import Foundation

class NoteViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate, UITextViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descTextView: UITextView!
    @IBOutlet weak var geoLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    
    var selectedNote: Note? = nil
    
    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        descTextView.delegate = self
        titleTextField.delegate = self
        
        let numberToolbar = UIToolbar(frame:CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        numberToolbar.barStyle = .default
        numberToolbar.items = [
        UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
        UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneWithNumberPad))]
        numberToolbar.sizeToFit()
        descTextView.inputAccessoryView = numberToolbar
        titleTextField.inputAccessoryView = numberToolbar
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        if(selectedNote != nil) {
            titleTextField.text = selectedNote?.title
            descTextView.text = selectedNote?.desc
            imageView.image = selectedNote?.image
            geoLabel.text = selectedNote?.geo
            
            deleteButton.isHidden = false
        } else {
            let date = Date()
            let dateFormatter = DateFormatter()
            
            dateFormatter.timeStyle = .short
            dateFormatter.dateStyle = .none
            
            let formattedDate = dateFormatter.string(from: date)
            
            getCityName { cityName in
                if let city = cityName {
                    self.geoLabel.text = "\(formattedDate), \(city)"
                } else {
                    print("City not found")
                }
            }
            
            deleteButton.isHidden = true
        }
        
        let imageTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(imageTapGestureRecognizer)
        
        let geoTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
        geoLabel.isUserInteractionEnabled = true
        geoLabel.addGestureRecognizer(geoTapGestureRecognizer)
    }

    @IBAction func saveButtonClick(_ sender: Any) {
        let appDelegete = UIApplication.shared.delegate as! AppDelegate
        let context: NSManagedObjectContext = appDelegete.persistentContainer.viewContext
        
        if ((titleTextField.text == "") && (descTextView.text == "")) {
            showEmptyNoteAlert()
        } else {
            if (selectedNote == nil) {
                let entity = NSEntityDescription.entity(forEntityName: "Note", in: context)
                let newNote = Note(entity: entity!, insertInto: context)
                newNote.id = nonDeletedNoteList.count as NSNumber
                newNote.title = titleTextField.text
                newNote.desc = descTextView.text
                newNote.image = imageView.image
                newNote.geo = geoLabel.text
                
                do {
                    try context.save()
                    noteList.append(newNote)
                    navigationController?.popViewController(animated: true)
                } catch {
                    print("context save error")
                }
            } else {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
                
                do {
                    let results: NSArray = try context.fetch(request) as NSArray
                    for result in results {
                        let note = result as! Note
                        if (note == selectedNote) {
                            note.title = titleTextField.text
                            note.desc = descTextView.text
                            note.image = imageView.image
                            note.geo = geoLabel.text
                            
                            try context.save()
                            navigationController?.popViewController(animated: true)
                        }
                    }
                } catch {
                    print("context fetch failed")
                }
            }
        }
    }

    @IBAction func deleteButtonClick(_ sender: Any) {
        let appDelegete = UIApplication.shared.delegate as! AppDelegate
        let context: NSManagedObjectContext = appDelegete.persistentContainer.viewContext
        
        if (selectedNote == nil) {
            navigationController?.popViewController(animated: true)
        } else {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
            
            do {
                let results: NSArray = try context.fetch(request) as NSArray
                for result in results {
                    let note = result as! Note
                    if (note == selectedNote) {
                        note.is_deleted = NSNumber(value: true)
                        
                        try context.save()
                        navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                print("context fetch failed")
            }
        }
    }
    
    @IBAction func refreshLocationButtonClick(_ sender: Any) {
        let date = Date()
        let dateFormatter = DateFormatter()
        
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .none
        
        let formattedDate = dateFormatter.string(from: date)
        
        getCityName { cityName in
            if let city = cityName {
                self.geoLabel.text = "\(formattedDate), \(city)"
            } else {
                print("City not found")
            }
        }
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary)
        {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self;
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary;
            imagePicker.allowsEditing = true;
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @objc func doneWithNumberPad() {
        descTextView.resignFirstResponder()
        titleTextField.resignFirstResponder()
    }
    
    @objc func labelTapped() {
        performSegue(withIdentifier: "locationSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "locationSegue") {
            let map = segue.destination as? LocationViewController
            let currentLocation = locationManager.location
            let latitude = currentLocation?.coordinate.latitude
            let longitude = currentLocation?.coordinate.longitude
            map!.latitude = latitude
            map!.longitude = longitude
            map!.dataHandler = { [weak self] data in self?.handleLocationData(city: data) }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let info = converFromUIImagePickerControllerInfoKeyDictionary(info)
        let selectedImage = info[converFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as! UIImage

        imageView.image = selectedImage
        self.dismiss(animated: true, completion: nil)
    }
    
    func getCityName(completion: @escaping (String?) -> Void) {
        guard let location = locationManager.location else {
            completion(nil)
            return
        }
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                completion(nil)
            }
            
            guard let placemark = placemarks?.first else {
                completion(nil)
                return
            }
            
            if let city = placemark.locality {
                completion(city)
            } else {
                completion(nil)
            }
        }
    }

    func handleLocationData(city: Any) {
        let tempGeoLabel = geoLabel.text
        let hour = tempGeoLabel?.components(separatedBy: ",")[0]
        geoLabel.text = "\(hour ?? ""), \(city)"
    }
    
    func showEmptyNoteAlert() {
        let alertController = UIAlertController(title: "Empty note", message: "You wanted to save empty note, please fill at least title or description, or go back", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}

fileprivate func converFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

fileprivate func converFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}

