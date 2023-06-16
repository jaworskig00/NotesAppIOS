import UIKit
import MapKit

class LocationViewController: UIViewController, UINavigationControllerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var latitude: Double? = nil
    var longitude: Double? = nil
    
    var dataHandler: ((Any) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        if (latitude != nil && longitude != nil) {
            let annotation = MKPointAnnotation()
            let centerCoordinate = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
            annotation.coordinate = centerCoordinate
            annotation.title = "Your location"
            mapView.addAnnotation(annotation)
            mapView.centerCoordinate = centerCoordinate
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func confirmButtonClick(_ sender: Any) {
        var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
        
        if let annotation = mapView.annotations.first as? MKPointAnnotation {
            coordinate = annotation.coordinate
        }
        
        getCityName(from: coordinate) { cityName in
            if let cityName = cityName {
                self.dataHandler?(cityName)
            } else {
                print("City name not available")
            }
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    @objc func handleMapTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            for annotation in mapView.annotations {
                mapView.removeAnnotation(annotation)
            }
            
            let tapPoint = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "Choosen Location"
            
            mapView.addAnnotation(annotation)
        }
    }
    
    func getCityName(from coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding failed: \(error.localizedDescription)")
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
}
