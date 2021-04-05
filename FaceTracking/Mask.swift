//
//  Mask.swift
//  FaceTracking
//
//  Created by zemin on 4/1/21.
//

import ARKit
import SceneKit

class Mask: SCNNode {
    
    // face geometry will be provided by ARKit which
    // matches the size, shape, topology and facial expression
    init(geometry: ARSCNFaceGeometry) {
        
        super.init()
        
        let mat = geometry.firstMaterial!
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = UIColor(red:0.0, green: 0.0,
                                       blue: 1.0, alpha: 1)
        self.geometry = geometry
    }
    
    required init?(coder: NSCoder) {
        fatalError("\(#function) has not been implemented !")
    }
    
    func update(withFaceAnchor anchor: ARFaceAnchor) {
        let faceGeometry = geometry as! ARSCNFaceGeometry
        faceGeometry.update(from: anchor.geometry)
    }
    
}
