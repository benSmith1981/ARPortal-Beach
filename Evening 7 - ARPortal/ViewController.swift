//
//  ViewController.swift
//  Evening 7 - ARPortal
//
//  Created by Ben Smith on 26/04/2018.
//  Copyright © 2018 Ben Smith. All rights reserved.
//

import UIKit
import ARKit
class ViewController: UIViewController {
    @IBOutlet var sceneView: ARSCNView!
    var config = ARWorldTrackingConfiguration()
    
    var planeFound = false
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var toast: UIVisualEffectView!
    @IBOutlet weak var instructions: UIVisualEffectView!
    var audioSource: SCNAudioSource = SCNAudioSource(fileNamed: "reggaSound.mp3")!
    var audioPlayer: SCNAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        config.planeDetection = .horizontal
//        self.sceneView.session.run(config)
        self.sceneView.delegate = self
        self.sceneView.automaticallyUpdatesLighting = true
        
        // Prevent the screen from being dimmed after a while.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Start a new session
        startNewSession()
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(addPortal))
        self.sceneView.addGestureRecognizer(tap)
        
        let instructionsTap = UITapGestureRecognizer.init(target: self, action: #selector(hideInstructions))
        instructions.addGestureRecognizer(instructionsTap)
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func startNewSession() {
        planeFound = false
        audioSource = SCNAudioSource(fileNamed: "reggaSound.mp3")!
        audioSource.loops = true
        // Decode the audio from disk ahead of time to prevent a delay in playback
        audioSource.load()
        audioSource.volume = 1
        audioPlayer = SCNAudioPlayer(source: self.audioSource)
        
        // hide toast
        self.toast.alpha = 0
        self.toast.frame = self.toast.frame.insetBy(dx: 5, dy: 5)
        showInstructions()
        // Create a session configuration with horizontal plane detection
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        config = configuration
        // Run the view's session
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }
    @objc func addPortal(sender: UIGestureRecognizer) {
        guard let view = sender.view as? ARSCNView, planeFound == false else {
            return
        }

        let touchLocation = sender.location(in: view)
        let hitTest = view.hitTest(touchLocation, types: .existingPlaneUsingExtent)
        if !hitTest.isEmpty, let results = hitTest.first  {
            planeFound = true
            if let scene = SCNScene.init(named: "Media.scnassets/Island/island.scn") {
                let island = scene.rootNode.childNode(withName: "Parent", recursively: true)
                let beach = scene.rootNode.childNode(withName: "Beach", recursively: true)
                
                let worldTransform = results.worldTransform
                    island?.position = SCNVector3.init(worldTransform.columns.3.x + 1,
                                                       worldTransform.columns.3.y-1,
                                                       worldTransform.columns.3.z - 4)
                DataLayer.shared.getPromoCode { (code) in
                    if let text = island?.childNode(withName: "PromoCode", recursively: true)?.geometry as? SCNText {
                        text.string = code
                        let node = island?.childNode(withName: "PromoCode", recursively: true)
                        if let audioPlayer = self.audioPlayer{
                            node?.addAudioPlayer(audioPlayer)
                        }

                        print("Promo code \(code)")
                    }
                }
                self.addWalls(nodeName: "sphere", portalNode: island!, maskName: "sphereMask")
                self.addWalls(nodeName: "rightWall", portalNode: island!, maskName: "mask")
                self.addWalls(nodeName: "leftWall", portalNode: island!, maskName: "mask")
                self.addWalls(nodeName: "backWall", portalNode: island!, maskName: "mask")
                self.addWalls(nodeName: "frontWallRight", portalNode: island!, maskName: "mask")
                self.addWalls(nodeName: "frontWallLeft", portalNode: island!, maskName: "mask")

                self.addWalls(nodeName: "backWallLeft", portalNode: island!, maskName: "mask")
                self.addWalls(nodeName: "roof", portalNode: island!, maskName: "mask")
                self.addWalls(nodeName: "floor", portalNode: island!, maskName: "mask")

                self.sceneView.scene.rootNode.addChildNode(island!)
            }
        }

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addWalls(nodeName: String, portalNode: SCNNode, maskName: String) {
        let child = portalNode.childNode(withName: nodeName, recursively: true)
//        child?.geometry?.firstMaterial?.diffuse.contents = UIImage.init(named: "Media.scnassets/portalAssets/\(imageName)")
        if let mask = child?.childNode(withName: maskName, recursively: false) {
            mask.geometry?.firstMaterial?.transparency = 0.00000001
        }
    }


}
extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor {
            DispatchQueue.main.async {
                self.showToast("Tap to go to the beach!")
            }
        }
    }
}
extension ViewController: ARSessionObserver {
    
    func sessionWasInterrupted(_ session: ARSession) {
        showToast("Session was interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        startNewSession()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        showToast("Session failed: \(error.localizedDescription)")
        startNewSession()
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        var message: String? = nil
        
        switch camera.trackingState {
        case .notAvailable:
            message = "Tracking not available"
        case .limited(.initializing):
            message = "Initializing AR session"
        case .limited(.excessiveMotion):
            message = "Too much motion"
        case .limited(.insufficientFeatures):
            message = "Not enough surface details"
        case .normal:
            message = "Move to find a horizontal surface"
        default:
            // We are only concerned with the tracking states above.
            message = "Camera changed tracking state"
        }
        
        message != nil ? showToast(message!) : hideToast()
    }
    

    
}

extension ViewController {
    
    func showToast(_ text: String) {
        label.text = text
        
        guard toast.alpha == 0 else {
            return
        }
        
        toast.layer.masksToBounds = true
        toast.layer.cornerRadius = 7.5
        
        UIView.animate(withDuration: 0.25, animations: {
            self.toast.alpha = 1
            self.toast.frame = self.toast.frame.insetBy(dx: -5, dy: -5)
        })
        
    }
    func showInstructions() {
        guard instructions.alpha == 0 else {
            return
        }
        
        instructions.layer.masksToBounds = true
        instructions.layer.cornerRadius = 7.5
        UIView.animate(withDuration: 0.25, animations: {
            self.instructions.alpha = 1
            self.instructions.frame = self.instructions.frame.insetBy(dx: 5, dy: 5)
        })
    }

    
    @objc func hideInstructions() {

        UIView.animate(withDuration: 0.25, animations: {
            self.instructions.alpha = 0
            self.instructions.frame = self.instructions.frame.insetBy(dx: 5, dy: 5)
        })
    }
    
    func hideToast() {
        UIView.animate(withDuration: 0.25, animations: {
            self.toast.alpha = 0
            self.toast.frame = self.toast.frame.insetBy(dx: 5, dy: 5)
        })
    }
}
