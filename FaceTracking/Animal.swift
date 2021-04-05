//
//  Animal.swift
//  FaceTracking
//
//  Created by zemin on 4/5/21.
//

import ARKit
import SceneKit

class Animal: SCNNode {
    
    let occlusionNode:SCNNode
    
    private var neutralBrowY: Float = 0
    private var neutralRightEyeX: Float = 0
    private var neutralRightEyeY: Float = 0
    private var neutralLeftEyeX: Float = 0
    private var neutralLeftEyeY: Float = 0
    private var neutralMouthY: Float = 0
    private var neutralNoseY: Float = 0
    
    private lazy var browNode = childNode(withName: "brow", recursively: true)!
    private lazy var eyeRightNode = childNode(withName: "eyeRight", recursively: true)!
    private lazy var pupilRightNode = childNode(withName: "pupilRight", recursively: true)!
    private lazy var eyeLeftNode = childNode(withName: "eyeLeft", recursively: true)!
    private lazy var pupilLeftNode = childNode(withName: "pupilLeft", recursively: true)!
    private lazy var mouthNode = childNode(withName: "mouth", recursively: true)!
    private lazy var noseNode = childNode(withName: "snout", recursively: true)!
    private lazy var pupilWidth: Float = {
        let (min,max) = pupilRightNode.boundingBox
        return max.x - min.x
    }()
    private lazy var pupilHeight: Float = {
        let (min,max) = pupilRightNode.boundingBox
        return max.y - min.y
    }()
    private lazy var mouthHeight: Float = {
        let (min,max) = mouthNode.boundingBox
        return max.y - min.y
    }()
    private lazy var noseHeight: Float = {
        let (min,max) = noseNode.boundingBox
        return max.y - min.y
    }()
    
    init(geometry: ARSCNFaceGeometry, animalName: String) {
        geometry.firstMaterial!.colorBufferWriteMask = []
        occlusionNode = SCNNode(geometry: geometry)
        occlusionNode.renderingOrder = -1
        
        super.init()
        self.geometry = geometry
        
        guard let url = Bundle.main.url(forResource: animalName,
                                        withExtension: "scn")
        else{
            fatalError("Missing resource ! ")
        }
        
        let node = SCNReferenceNode(url: url)!
        node.load()
        
        addChildNode(node)
        
        neutralBrowY = browNode.position.y
        neutralRightEyeX = pupilRightNode.position.x
        neutralRightEyeY = pupilRightNode.position.y
        neutralLeftEyeX = pupilLeftNode.position.x
        neutralLeftEyeY = pupilLeftNode.position.y
        neutralMouthY = mouthNode.position.y
        neutralNoseY = noseNode.position.y
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
    
    func update(withFaceAnchor anchor: ARFaceAnchor) {
//        let faceGeometry = geometry as! ARSCNFaceGeometry
//        faceGeometry.update(from: anchor.geometry)
        
        blendShapes = anchor.blendShapes
    }
    
    var blendShapes: [ARFaceAnchor.BlendShapeLocation: Any] = [:] {
        didSet {
            // the factor describing how much our brow is moved up
            guard
                let browInnerUp = blendShapes[.browInnerUp] as? Float,
                
                let eyeLookInRight = blendShapes[.eyeLookInRight] as? Float,
                let eyeLookOutRight = blendShapes[.eyeLookUpRight] as? Float,
                let eyeLookUpRight = blendShapes[.eyeLookUpRight] as? Float,
                let eyeLookDownRight = blendShapes[.eyeLookDownRight] as? Float,
                let eyeBlinkRight = blendShapes[.eyeBlinkRight] as? Float,
                
                let eyeLookInLeft = blendShapes[.eyeLookInLeft] as? Float,
                let eyeLookOutLeft = blendShapes[.eyeLookUpLeft] as? Float,
                let eyeLookUpLeft = blendShapes[.eyeLookUpLeft] as? Float,
                let eyeLookDownLeft = blendShapes[.eyeLookDownLeft] as? Float,
                let eyeBlinkLeft = blendShapes[.eyeBlinkLeft] as? Float,
                
                let mouthOpen = blendShapes[.jawOpen] as? Float,
                
                let noseUp = blendShapes[.noseSneerRight] as? Float
            

            else {return}
            
            
            let browHeight = (browNode.boundingBox.max .y - browNode.boundingBox.min.y)
            
            browNode.position.y = neutralBrowY + browHeight * browInnerUp
            
            let rightPupilPos = SCNVector3(
                x:(neutralRightEyeX - pupilWidth) * (eyeLookInRight - eyeLookOutRight),
                y:(neutralRightEyeY - pupilHeight) * (eyeLookUpRight - eyeLookDownRight),
                z: pupilRightNode.position.z)
            
            let leftPupilPos = SCNVector3(
                x:(neutralLeftEyeX - pupilWidth) * (eyeLookInLeft - eyeLookOutLeft),
                y:(neutralLeftEyeY - pupilHeight) * (eyeLookUpLeft - eyeLookDownLeft),
                z: pupilLeftNode.position.z)
            
            pupilRightNode.position = rightPupilPos
            eyeRightNode.scale.y = 1 - eyeBlinkRight
            
            pupilLeftNode.position = leftPupilPos
            eyeLeftNode.scale.y = 1 - eyeBlinkLeft
            
            mouthNode.position.y = neutralMouthY - mouthHeight * mouthOpen
            mouthNode.scale.x = 1 + mouthOpen
            mouthNode.scale.y = 1 + mouthOpen
            
            noseNode.position.y = neutralNoseY + noseHeight * noseUp
        }
    }
}
