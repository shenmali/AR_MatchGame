//
//  ViewController.swift
//  AR_MatchGame
//
//  Created by shenmali on 28/05/23.
//

import UIKit
import RealityKit
import Combine

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // teather to virtual world
        let anchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.2, 0.2])
        
        // simulates everything
        arView.scene.addAnchor(anchor)
        
        var cards: [Entity] = []
        // 16 cards to be placed in scene
        for _ in 1...16 {
            let box = MeshResource.generateBox(width: 0.04, height: 0.002, depth: 0.04)
            let metalMaterial = SimpleMaterial(color: .darkGray, isMetallic: true)
            let model = ModelEntity(mesh: box, materials: [metalMaterial])
            
            model.generateCollisionShapes(recursive: true)
            
            cards.append(model)
        }
        
        for (index, card) in cards.enumerated() {
            // positioning of cards
            let x = Float(index % 4) // 4 cards per axis
            let z = Float(index / 4)
            
            card.position = [x * 0.1, 0, z * 0.1]
            anchor.addChild(card)
        }
        
        // Occlusion Box
        // Hides rendered entities
        let boxSize: Float = 0.7
        let occlusionBoxMesh = MeshResource.generateBox(size: boxSize)
        let occlusionBox = ModelEntity(mesh: occlusionBoxMesh, materials: [OcclusionMaterial()])
        
        occlusionBox.position.y = -boxSize / 2
        anchor.addChild(occlusionBox)
        
        // Ensures load request would cancel before assets are loaded
        var cancellable: AnyCancellable? = nil
        
        // Load model
        cancellable = ModelEntity.loadModelAsync(named: "banana")
            .append(ModelEntity.loadModelAsync(named: "apple"))
            .append(ModelEntity.loadModelAsync(named: "watermelon"))
            .append(ModelEntity.loadModelAsync(named: "orange"))
            .append(ModelEntity.loadModelAsync(named: "cherry"))
            .append(ModelEntity.loadModelAsync(named: "eggplant"))
            .append(ModelEntity.loadModelAsync(named: "strawberry"))
            .append(ModelEntity.loadModelAsync(named: "grapes"))
            .collect()
            .sink(receiveCompletion: {error in
                print("Error: \(error)")
                      cancellable?.cancel()
            }, receiveValue: {entities in
                var objects: [ModelEntity] = []
                
                // scale down entities
                for entity in entities {
                    entity.setScale(SIMD3<Float>(0.0005, 0.0005, 0.0005), relativeTo: anchor)
                    entity.generateCollisionShapes(recursive: true)
                    for _ in 1...2 {
                        objects.append(entity.clone(recursive: true))
                    }
                }
                objects.shuffle()
                
                // place elements on cards
                for (index, object) in objects.enumerated() {
                    cards[index].addChild(object)
                    
                    // rotate cards
                    cards[index].transform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0])
                }
                
                cancellable?.cancel()
            })
    }
    
    @IBAction func onTap(_ sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: arView)
        if let card = arView.entity(at: tapLocation) {
            if card.transform.rotation.angle == .pi {
                var flipDownTransform = card.transform
                flipDownTransform.rotation = simd_quatf(angle: 0, axis: [1, 0, 0])
                card.move(to: flipDownTransform, relativeTo: card.parent, duration: 0.25, timingFunction: .easeInOut)
            }
            else {
                var flipUpTransform = card.transform
                flipUpTransform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0])
                card.move(to: flipUpTransform, relativeTo: card.parent, duration: 0.25, timingFunction: .easeInOut)
            }
        }
        
    }
}
