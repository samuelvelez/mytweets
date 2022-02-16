//
//  AddPostViewController.swift
//  myTweets
//
//  Created by Samuel on 7/2/22.
//

import UIKit
import Simple_Networking
import SVProgressHUD
import NotificationBannerSwift
import FirebaseStorage
import AVFoundation
import AVKit//simd
import MobileCoreServices
import CoreLocation

class AddPostViewController: UIViewController {

    //MARK: - IBOutlets
    @IBOutlet weak var postTextView : UITextView!
    @IBOutlet weak var previewImageView : UIImageView!
    @IBOutlet weak var videoButton: UIButton!
    
    //MARK: - IBActions
    @IBAction func openCameraAction(){
        //self.openCamera()
        let alert = UIAlertController(title: "Cámara", message: "Selecciona una opcion", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Foto", style: .default, handler: { _ in
            self.openCamera()
        }))
        alert.addAction(UIAlertAction(title: "Video", style: .default, handler: { _ in
            self.openVideoCamera()
        }))
        alert.addAction(UIAlertAction(title: "Cancelar", style: .destructive, handler: nil))
        
        present(alert, animated: true, completion: nil)
        
        //self.openVideoCamera()
    }
    @IBAction func addPostAction(){
        //uploadPhotoToFirebase()
        
        
        if currentVideoURL != nil {
            uploadVideoToFirebase()
            return
        }
        if previewImageView.image != nil{
            uploadVideoToFirebase()
            return
        }
        savePost(imageUrl: nil, videoUrl: nil)
        //savePost()
        
    }
    @IBAction func openPreviewAction() {
        print("preview")
        guard let currentVideoUrl = currentVideoURL else{
            return
        }
        let avPlayer = AVPlayer(url: currentVideoUrl)
        let avPlayerController = AVPlayerViewController()
        avPlayerController.player = avPlayer
        
        present(avPlayerController, animated: true){
            avPlayerController.player?.play()
        }
    }
    @IBAction func dismissAction(){
        dismiss(animated: true)
    }
    //MARK: - Properties
    private var imagePicker: UIImagePickerController?
    private var currentVideoURL: URL?
    private var locationManager: CLLocationManager?
    private var userLocation: CLLocation?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        videoButton.isHidden = true
        requestLocation()
    }
    
    private func requestLocation(){
        //validar que el usuario tenga el gps activo y disponible
        guard CLLocationManager.locationServicesEnabled() else{
            return
        }
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestAlwaysAuthorization()
        locationManager?.startUpdatingLocation()
    }
    private func openVideoCamera(){
        imagePicker = UIImagePickerController()
        imagePicker?.sourceType = .camera
        imagePicker?.mediaTypes = [kUTTypeMovie as String]
        imagePicker?.cameraFlashMode = .off
        imagePicker?.cameraCaptureMode = .video
        imagePicker?.videoQuality = .typeMedium
        imagePicker?.videoMaximumDuration = TimeInterval(5)
        imagePicker?.allowsEditing = true
        imagePicker?.delegate = self
        
        guard let imagePicker = imagePicker else {
            return
        }
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func openCamera(){
        imagePicker = UIImagePickerController()
        imagePicker?.sourceType = .camera
        imagePicker?.cameraFlashMode = .off
        imagePicker?.cameraCaptureMode = .photo
        imagePicker?.allowsEditing = true
        imagePicker?.delegate = self
        
        guard let imagePicker = imagePicker else {
            return
        }
        present(imagePicker, animated: true, completion: nil)
    }

    private func uploadPhotoToFirebase(){
        // 1 asegurra ue la foto exista
        // 2 compirmir imagen u convertirla en data
        guard let imageSaved = previewImageView.image,
              
              let imageSavedData: Data = imageSaved.jpegData(compressionQuality: 0.1) else{
                  
                  return
              }
        SVProgressHUD.show()
        // 3 confirgutracion para guardar foto en firebase
        let metaDataConfig = StorageMetadata()
        metaDataConfig.contentType = "image/jpg"
        
        // 4 referecnai al storage de firabse
        let storage = Storage.storage()
        
        // 5 crear nombre e la imagen a subir
        let imageName = UUID().uuidString
        
        //6 referencia a la caperta donde se va a guardar la foto
        let folderReference = storage.reference(withPath: "fotos-mytweets/\(imageName).jpg")
        
        //7 subir la foto a firebase
        DispatchQueue.global(qos: .background).async {
            folderReference.putData(imageSavedData,metadata: metaDataConfig){
                (metaData: StorageMetadata?, error: Error?) in
                
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    
                    if let error = error {
                        NotificationBanner(title: "Error", subtitle: error.localizedDescription, style: .danger).show()
                        return
                    }
                    
                    // obtener la URL de descarga
                    folderReference.downloadURL { (url: URL?, error: Error?) in
                        //print(url?.absoluteString ?? "NO")
                        let downloadURL = url?.absoluteString ?? ""
                        self.savePost(imageUrl: downloadURL, videoUrl: nil)
                    }
                }
            }
        }
    }
    
    private func uploadVideoToFirebase(){
        // 1 asegurarnos que el video exista
        // 2 convertir en data el video
        guard let currentVideoSavedUrl = currentVideoURL,
              let videoData: Data = try? Data(contentsOf: currentVideoSavedUrl) else{
                  return
              }
              
        SVProgressHUD.show()
        // 3 confirgutracion para guardar foto en firebase
        let metaDataConfig = StorageMetadata()
        metaDataConfig.contentType = "video/mp4"
        
        // 4 referecnai al storage de firabse
        let storage = Storage.storage()
        
        // 5 crear nombre e la imagen a subir
        let videoName = UUID().uuidString
        
        //6 referencia a la caperta donde se va a guardar la foto
        let folderReference = storage.reference(withPath: "video-mytweets/\(videoName).mp4")
        
        //7 subir el video a firebase
        DispatchQueue.global(qos: .background).async {
            folderReference.putData(videoData,metadata: metaDataConfig){
                (metaData: StorageMetadata?, error: Error?) in
                
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    
                    if let error = error {
                        NotificationBanner(title: "Error", subtitle: error.localizedDescription, style: .danger).show()
                        return
                    }
                    
                    // obtener la URL de descarga
                    folderReference.downloadURL { (url: URL?, error: Error?) in
                        //print(url?.absoluteString ?? "NO")
                        let downloadURL = url?.absoluteString ?? ""
                        self.savePost(imageUrl: nil, videoUrl: downloadURL)
                    }
                }
            }
        }
    }
    
    private func savePost(imageUrl: String?, videoUrl: String? ){
        //crear un request de localzacion
        var postLocation: PostRequestLocation?
        
        if let userLocation = userLocation {
            postLocation = PostRequestLocation(latitude: (userLocation.coordinate.latitude), longitude: userLocation.coordinate.longitude)
        }
        
        //crear request
        let request = PostRequest(text: postTextView.text, imageUrl: imageUrl, videoUrl: videoUrl, location: postLocation)
        // 2 indicar carga al usuario
        SVProgressHUD.show()
        
        //3 llamar al servicio del post
        SN.post(endpoint: Endpoints.post, model: request) { (response: SNResultWithEntity<Post, ErrorResponse>) in
            //cerrar indicador de carga
            SVProgressHUD.dismiss()
            
            switch response{
            case .success:
                self.dismiss(animated: true)
            case .error(error: let error):
                NotificationBanner(title: "Error", subtitle: error.localizedDescription, style: .danger).show()
            case .errorResult(entity: let entity):
                NotificationBanner(title: "Error", subtitle: entity.error, style: .warning).show()
            }
            
        }
    }
    
}

//MARK: - UIImagePickerControllerDelegate
extension AddPostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //cerrar camara
        imagePicker?.dismiss(animated: true, completion: nil)
        
        //capturar imagen
        if info.keys.contains(.originalImage){
            previewImageView.isHidden = false
            previewImageView.image = info[.originalImage] as? UIImage
        }
        
        //capturar url del video
        if info.keys.contains(.mediaURL), let recordedVideoURL = (info[.mediaURL] as? URL)?.absoluteURL{
            videoButton.isHidden = false
            currentVideoURL = recordedVideoURL
        }
    }
    
}

//MARK: - CLLocationManagerDelegate
extension AddPostViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let bestLocation = locations.last else{
            return
        }
        // ya tenemos una ubicacion por lo menos 😇
        userLocation = bestLocation
        
    }
}
