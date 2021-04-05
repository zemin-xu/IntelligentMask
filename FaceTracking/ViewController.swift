//
//  ViewController.swift
//  FaceTracking
//
//  Created by zemin on 4/1/21.
//

import UIKit
import SceneKit
import ARKit

import Vision

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    // MARK: - Enum
    enum ContentType: Int {
        case pig
        case rabbit
    }
    
    
    // MARK: - Outlets
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var emotionLabel: UILabel!
    @IBOutlet weak var switchTypeButton: UIButton!
    
    
    // MARK: - Properties
    
    var session: ARSession {
        return sceneView.session
    }
    
    var anchorNode: SCNNode? // ARFaceAnchor object
    var mask: Mask?
    var pig: Animal?
    var rabbit: Animal?
    var contentTypeSelected: ContentType = .rabbit
    
    var label:String = ""
    var shouldSkipFrame = 1
    var predictEvery = 60 // one detection per second now
    var detectionRequest : VNCoreMLRequest!
    let predictionQueue = DispatchQueue(label: "predictionQueue",
                                        qos: .userInitiated,
                                        attributes: [],
                                        autoreleaseFrequency: .inherit,
                                        target: nil)
    
    // MARK: - UI Action
    
    @IBAction func switchTypeButtonPressed(_ sender: Any) {
        //print("change type button pressed")
        switch(contentTypeSelected){
        case .rabbit:
            contentTypeSelected = .pig
        case .pig:
            contentTypeSelected = .rabbit
        }
        resetTracking()
        createFaceGeometry()
        
    }
    
    // MARK: - View Management
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSceneKit()
        
        createFaceGeometry()
        
        // Create a new scene
        //let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        //sceneView.scene = scene
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        guard let mlmodel = try?ExpressionRecognition(configuration: .init()).model,
              let detector = try?VNCoreMLModel(for: mlmodel) else {
            print("fail to create detector")
            return
        }
        
        detectionRequest = VNCoreMLRequest(model: detector) {
            [weak self]request, error in self?.detectionRequestHandler(request: request, error:error)
        }
      
        detectionRequest.imageCropAndScaleOption = .centerCrop
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        //let configuration = ARWorldTrackingConfiguration()

        // prevent device from going to sleep
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Run the view's session
        //sceneView.session.run(configuration)
        resetTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //
        UIApplication.shared.isIdleTimerDisabled = false
        // Pause the view's session
        sceneView.session.pause()
        

    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    // this func get called for each anchor added to the scene
    // pass in as value of anchorNode property
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        anchorNode = node
        setupfaceNodeContent()
    }
    
    // when face is updated,the update function of Mask is called
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        switch contentTypeSelected {

        case .rabbit:
            //mask?.update(withFaceAnchor: faceAnchor)
            rabbit?.update(withFaceAnchor: faceAnchor)
        case .pig:
            pig?.update(withFaceAnchor: faceAnchor)
        }
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        shouldSkipFrame = (shouldSkipFrame + 1) % predictEvery
        
        // parse inside this condition
        if shouldSkipFrame == 0 {
            predictionQueue.async {
                let image = frame.capturedImage
                
                let cm = CIImage(cvPixelBuffer: image)
                
                let img = UIImage(ciImage: cm)
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let path = documentsDirectory.appendingPathComponent(String(Date().timeIntervalSinceReferenceDate) + ".jpg")
                
                let jpg = img.jpegData(compressionQuality: 0.25)

                do{
                    try jpg?.write(to: path)
                }
                catch{
                    print("captured image write error")
                }

                
                /// - Tag: PassingFramesToVision

                // Invoke a VNRequestHandler with that image
                let handler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .right, options: [:])

                do {
                    try handler.perform([self.detectionRequest])
                } catch {
                    print("CoreML request failed with error: \(error.localizedDescription)")
                }
            }
        }
        emotionLabel.text = label
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        print(" Session failed ! ")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        print(" Session interrupted ! ")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        print(" Session interruption ended. ")
    }
    
    
}

// MARK: - Private methods

private extension ViewController {
    func setupSceneKit() {
        // Set the view's delegate
        sceneView.delegate = self
        
        sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = false
        sceneView.scene.lightingEnvironment.intensity = 1.0
    }
    
    func resetTracking() {
        guard ARFaceTrackingConfiguration.isSupported else {
            print(" Face Tracking Not Supported ! ")
            return
        }
        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = true
        config.providesAudioData = false
        
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func createFaceGeometry()
    {
        print(" Creating face geometry. ")
        
        let device = sceneView.device!
        
        switch contentTypeSelected {
        case .rabbit:
            let animalGeometry = ARSCNFaceGeometry(device: device)!
            rabbit = Animal(geometry: animalGeometry, animalName:  "rabbit")
//            case .mask:
//                    let maskGeometry = ARSCNFaceGeometry(device: device)!
//                    mask = Mask(geometry: maskGeometry)
            case .pig:
                    let animalGeometry = ARSCNFaceGeometry(device: device)!
                    pig = Animal(geometry: animalGeometry, animalName: "pig")
        }
        
        
    }
    
    func setupfaceNodeContent() {
        guard let node = anchorNode else { return }
        
        print(" Set node to anchorNode. ")
        
        // remove any child nodes it contains
        node.childNodes.forEach { $0.removeFromParentNode() }
        
        switch contentTypeSelected {
            case .rabbit:
                if let content = rabbit {
                    node.addChildNode(content)
                }
//            case .mask:
//                if let content = mask {
//                    node.addChildNode(content)
//            }
               
                
        case .pig:
            if let content = pig {
                node.addChildNode(content)
            }
            
        }
    }
        
    
    func detectionRequestHandler(request: VNRequest, error: Error?) {
        // Perform several error checks before proceeding
        if let error = error {
            print("An error occurred with the vision request: \(error.localizedDescription)")
            return
        }
        guard let request = request as? VNCoreMLRequest else {
            print("Vision request is not a VNCoreMLRequest")
            return
        }
        guard let observations = request.results as? [VNCoreMLFeatureValueObservation] else {
            print("Request did not return recognized objects: \(request.results?.debugDescription ?? "[No results]")")
            return
        }
    
        let array = observations[0].featureValue.multiArrayValue!
        var val:Float = 0
        var index = -1

            for i in 0...6{
                if val < Float(array[i])
                {
                    val = Float(array[i])
                    index = i
                }
            }
        switch index{
        case -1:
            label = "Not available"
        case 0:
            label = "Angry"
        case 1:
            label = "Disgust"
        case 2:
            label = "Fear"
        case 3:
            label = "Happy"
        case 4:
            label = "Sad"
            case 5:
                label = "Surprise"
            case 6:
                label = "Neutral"
        default:
            label = "Not available"
        }
    }
}
